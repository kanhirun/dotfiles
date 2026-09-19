import { Clipboard, open, showHUD, showInFinder } from "@raycast/api";
import {
  buildRecordingPath,
  explainMissingMic,
  findMic,
  frontmostWindow,
  getPreferences,
  getSessions,
  getTargets,
  parseFps,
  primaryScreen,
  resolveShareLink,
  startRecording,
  stopRecording,
} from "./cap";

export async function startFromPreferences(): Promise<void> {
  const preferences = getPreferences();

  const active = await getSessions();
  if (active.length > 0) {
    await showHUD("⏺ Cap is already recording");
    return;
  }

  const targets = await getTargets();

  let screenId: string | undefined;
  let windowId: string | undefined;
  let label: string | undefined;

  if (preferences.target === "window") {
    const window = frontmostWindow(targets.windows);
    if (window) {
      windowId = window.id;
      label = `${window.ownerName} window`;
    }
  }
  if (!windowId) {
    const screen = primaryScreen(targets.screens);
    if (!screen) {
      throw new Error("No screen is available to capture.");
    }
    screenId = screen.id;
    label = label ?? screen.name;
  }

  const micName = preferences.micName?.trim() ?? "";
  const mic = micName ? findMic(targets.mics, micName) : undefined;
  if (micName && !mic) {
    throw new Error(
      explainMissingMic(
        micName,
        targets.mics.map((entry) => entry.name),
      ),
    );
  }

  const systemAudio = preferences.systemAudio ?? false;

  await startRecording({
    screen: screenId,
    window: windowId,
    mic: mic?.name,
    systemAudio,
    fps: parseFps(preferences.fps),
    path: buildRecordingPath(),
  });

  const parts = [label ?? "screen"];
  if (mic) {
    parts.push("mic");
  }
  if (systemAudio) {
    parts.push("system audio");
  }

  await showHUD(`⏺ Recording: ${parts.join(" + ")}`);
}

export async function stopAndDeliver(): Promise<void> {
  const afterStop = getPreferences().afterStop ?? "copy";

  const sessions = await getSessions();
  if (sessions.length === 0) {
    await showHUD("No Cap recording is active");
    return;
  }

  const session = sessions[0];
  await showHUD("⏳ Finishing upload…");
  const stopped = await stopRecording(session.recordingId);

  const link = await resolveShareLink(stopped, session.startedAt);
  if (!link) {
    await showHUD("✅ Recording saved, but no share link was found");
    await showInFinder(stopped.path);
    return;
  }

  if (afterStop === "copy" || afterStop === "copyAndOpen") {
    await Clipboard.copy(link);
  }
  if (afterStop === "open" || afterStop === "copyAndOpen") {
    await open(link);
  }

  await showHUD(afterStop === "open" ? `✅ Opened ${link}` : `✅ Link copied: ${link}`);
}
