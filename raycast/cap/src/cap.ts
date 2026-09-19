import { execFile } from "node:child_process";
import { existsSync, mkdirSync, readFileSync } from "node:fs";
import { homedir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";
import { getPreferenceValues } from "@raycast/api";

const execFileAsync = promisify(execFile);

export type AfterStop = "copy" | "open" | "copyAndOpen";

export interface Preferences {
  target?: "screen" | "window";
  micName?: string;
  systemAudio?: boolean;
  afterStop?: AfterStop;
  fps?: string;
  recordingsDir?: string;
  capPath?: string;
}

export interface Screen {
  index: number;
  id: string;
  name: string;
  primary: boolean;
}

export interface Window {
  index: number;
  id: string;
  name: string;
  ownerName: string;
  bundleIdentifier?: string;
}

export interface Camera {
  index: number;
  deviceId: string;
  displayName: string;
}

export interface Mic {
  index: number;
  name: string;
}

export interface Targets {
  screens: Screen[];
  windows: Window[];
  cameras: Camera[];
  mics: Mic[];
}

export interface Session {
  recordingId: string;
  pid: number;
  path: string;
  status: string;
  alive: boolean;
  /** Unix seconds. */
  startedAt: number;
  error?: string;
}

export interface StartedRecording {
  recordingId: string;
  pid: number;
  path: string;
}

export interface StoppedRecording {
  path: string;
  recordingMetaExists: boolean;
  shareUrl?: string;
}

export interface Cap {
  id: string;
  title?: string;
  shareUrl?: string;
  createdAt?: string;
}

export interface RecordOptions {
  screen?: string;
  window?: string;
  mic?: string;
  systemAudio?: boolean;
  fps?: number;
  path: string;
}

/** Raycast spawns commands with a minimal PATH, so the binary is always resolved absolutely. */
const FALLBACK_BINARIES = [
  join(homedir(), ".cap", "bin", "cap"),
  "/Applications/Cap.app/Contents/MacOS/cap-cli",
];

const EXEC_OPTIONS = { maxBuffer: 64 * 1024 * 1024, timeout: 180_000 };

export function getPreferences(): Preferences {
  return getPreferenceValues<Preferences>();
}

export function expandTilde(path: string): string {
  return path.startsWith("~") ? join(homedir(), path.slice(1)) : path;
}

export function resolveBinary(): string {
  const configured = getPreferences().capPath?.trim();
  if (configured) {
    const path = expandTilde(configured);
    if (!existsSync(path)) {
      throw new Error(`No cap binary at ${path}. Update the Cap CLI Path preference.`);
    }
    return path;
  }

  const found = FALLBACK_BINARIES.find((candidate) => existsSync(candidate));
  if (!found) {
    throw new Error("Could not find the Cap CLI. Install Cap, or set the Cap CLI Path preference.");
  }
  return found;
}

/**
 * macOS attributes screen capture to the process that spawned the CLI, so the
 * permission Cap itself holds does not carry over to a Raycast-launched recording.
 */
function describeFailure(message: string): string {
  if (/declined TCCs|TCCs for application|not authorized|permission/i.test(message)) {
    return "Screen Recording permission is missing. Grant it to Raycast in System Settings › Privacy & Security › Screen & System Audio Recording, then restart Raycast.";
  }
  return message;
}

async function run(args: string[]): Promise<string> {
  try {
    const { stdout } = await execFileAsync(resolveBinary(), args, EXEC_OPTIONS);
    return stdout;
  } catch (error) {
    const stderr = (error as { stderr?: string }).stderr?.trim();
    const stdout = (error as { stdout?: string }).stdout?.trim();
    const embedded = stdout ? findEventError(stdout) : undefined;
    const message = embedded ?? stderr ?? (error as Error).message;
    throw new Error(describeFailure(message));
  }
}

function findEventError(stdout: string): string | undefined {
  for (const event of parseNdjson(stdout)) {
    if (typeof event.error === "string") {
      return event.error;
    }
  }
  return undefined;
}

function parseNdjson(stdout: string): Record<string, unknown>[] {
  const events: Record<string, unknown>[] = [];
  for (const line of stdout.split("\n")) {
    const trimmed = line.trim();
    if (!trimmed.startsWith("{")) {
      continue;
    }
    try {
      events.push(JSON.parse(trimmed) as Record<string, unknown>);
    } catch {
      // A partially flushed line is not fatal; the event we need may still follow.
    }
  }
  return events;
}

async function runJson<T>(args: string[]): Promise<T> {
  const stdout = await run([...args, "--json"]);
  return JSON.parse(stdout) as T;
}

async function runEvents(args: string[]): Promise<Record<string, unknown>[]> {
  const events = parseNdjson(await run([...args, "--json"]));
  const failure = events.find((event) => typeof event.error === "string");
  if (failure) {
    throw new Error(describeFailure(failure.error as string));
  }
  return events;
}

export async function getTargets(): Promise<Targets> {
  return runJson<Targets>(["targets"]);
}

/** Stale sessions linger in `record status` with status "error", so both fields are checked. */
export async function getSessions(): Promise<Session[]> {
  const sessions = await runJson<Session[]>(["record", "status"]);
  return sessions.filter((session) => session.alive && session.status === "recording");
}

export async function startRecording(options: RecordOptions): Promise<StartedRecording> {
  const args = ["record", "start", "--mode", "instant", "--path", options.path, "--detach"];

  if (options.window) {
    args.push("--window", options.window);
  } else if (options.screen) {
    args.push("--screen", options.screen);
  }
  if (options.mic) {
    args.push("--mic", options.mic);
  }
  if (options.systemAudio) {
    args.push("--system-audio");
  }
  if (options.fps) {
    args.push("--fps", String(options.fps));
  }

  const started = (await runEvents(args)).find((event) => event.type === "started");
  if (!started) {
    throw new Error("Cap did not report the recording as started.");
  }
  return started as unknown as StartedRecording;
}

export async function stopRecording(recordingId: string): Promise<StoppedRecording> {
  const events = await runEvents(["record", "stop", "--id", recordingId, "--timeout", "120"]);
  const stopped = events.find((event) => event.type === "stopped");
  if (!stopped) {
    throw new Error("Cap did not report the recording as stopped.");
  }
  return stopped as unknown as StoppedRecording;
}

export async function listCaps(): Promise<Cap[]> {
  const result = await runJson<{ caps?: Cap[] }>(["caps", "list"]);
  return result.caps ?? [];
}

function normalize(value: string): string {
  return value.trim().toLowerCase();
}

export function findMic(mics: Mic[], match: string): Mic | undefined {
  const needle = normalize(match);
  if (!needle) {
    return undefined;
  }
  return mics.find((mic) => normalize(mic.name).includes(needle));
}

/**
 * A recording that silently drops the camera looks like a success until you watch it
 * back, so a configured device that cannot be found is a hard failure. An empty device
 * list means Raycast lacks the permission, not that the hardware is absent.
 */
export function explainMissingMic(match: string, available: string[]): string {
  if (available.length === 0) {
    return "No microphone is visible to Raycast. Grant it access in System Settings › Privacy & Security › Microphone, then restart Raycast. To record without one, clear the Microphone preference.";
  }
  return `No microphone matches "${match}". Available: ${available.join(", ")}. Update the Microphone preference, or clear it to record without one.`;
}

export function primaryScreen(screens: Screen[]): Screen | undefined {
  return screens.find((screen) => screen.primary) ?? screens[0];
}

/**
 * `targets` lists windows front-to-back, but Raycast is itself frontmost whenever a
 * command runs, so its own windows are skipped.
 */
export function frontmostWindow(windows: Window[]): Window | undefined {
  return windows.find(
    (window) => !/raycast/i.test(window.ownerName) && !/raycast/i.test(window.bundleIdentifier ?? ""),
  );
}

export function buildRecordingPath(when: Date = new Date()): string {
  const directory = expandTilde(getPreferences().recordingsDir?.trim() || "~/Movies/Cap Recordings");
  mkdirSync(directory, { recursive: true });

  const stamp = [
    when.getFullYear(),
    String(when.getMonth() + 1).padStart(2, "0"),
    String(when.getDate()).padStart(2, "0"),
    "-",
    String(when.getHours()).padStart(2, "0"),
    String(when.getMinutes()).padStart(2, "0"),
    String(when.getSeconds()).padStart(2, "0"),
  ].join("");

  let candidate = join(directory, `Cap ${stamp}.cap`);
  let suffix = 2;
  // Cap refuses a path that already exists, including an empty directory.
  while (existsSync(candidate)) {
    candidate = join(directory, `Cap ${stamp} (${suffix++}).cap`);
  }
  return candidate;
}

export function parseFps(value: string | undefined): number | undefined {
  const fps = Number.parseInt((value ?? "").trim(), 10);
  if (!Number.isFinite(fps)) {
    return undefined;
  }
  return Math.min(120, Math.max(1, fps));
}

function linkFromMeta(projectPath: string): string | undefined {
  try {
    const meta = JSON.parse(readFileSync(join(projectPath, "recording-meta.json"), "utf8"));
    const sharing = meta?.sharing ?? meta?.upload ?? {};
    const link = sharing.link ?? sharing.shareUrl ?? meta?.shareUrl;
    if (typeof link === "string" && link.startsWith("http")) {
      return link;
    }
    const id = sharing.id ?? sharing.videoId ?? meta?.videoId;
    if (typeof id === "string" && id) {
      return `https://cap.so/s/${id}`;
    }
  } catch {
    // The block is only written once the upload registers; the library is the fallback.
  }
  return undefined;
}

const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Instant recordings upload while they run, but the Cap appears in the library a moment
 * after the CLI reports the stop, so the library is polled rather than read once.
 */
export async function resolveShareLink(
  stopped: StoppedRecording,
  startedAtUnixSeconds: number,
): Promise<string | undefined> {
  if (stopped.shareUrl) {
    return stopped.shareUrl;
  }

  const fromMeta = linkFromMeta(stopped.path);
  if (fromMeta) {
    return fromMeta;
  }

  const notBefore = (startedAtUnixSeconds - 120) * 1000;
  for (let attempt = 0; attempt < 6; attempt++) {
    try {
      const caps = await listCaps();
      const newest = caps
        .filter((cap) => cap.shareUrl && Date.parse(cap.createdAt ?? "") >= notBefore)
        .sort((a, b) => Date.parse(b.createdAt ?? "") - Date.parse(a.createdAt ?? ""))[0];
      if (newest?.shareUrl) {
        return newest.shareUrl;
      }
    } catch {
      // The recording is already safe on disk; a library lookup that fails should
      // degrade to "no link", never to a failed stop.
    }
    await delay(1500);
  }
  return undefined;
}
