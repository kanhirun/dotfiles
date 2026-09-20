# Shell session transcripts

Interactive zsh sessions are recorded with `script`. Use them when I refer to
something that happened in my terminal without pasting it.

## Where they are

```
~/.local/state/shell-logs/<project-dirname>-<YYYYmmdd-HHMMSS>.log
```

Named for the directory the shell started in. Directory is `0700`, files `0600`.

Not recorded: shells running under Claude Code, shells inside Neovim's terminal,
and any shell started with `NO_TRANSCRIPT=1`. So a missing log means one of those,
not that nothing happened.

## Finding the right one

```
ls -lt ~/.local/state/shell-logs/ | head
```

A log is written continuously while its shell is open, so **mtime is liveness**:
modified seconds ago means that session is active right now; modified an hour ago
means it is idle. Match the project by filename prefix. When several sessions
share a prefix they differ only by start time — prefer the most recently modified,
not the most recently started, unless I say otherwise.

**A transcript is deleted when its own shell exits.** Everything on disk therefore
belongs to a session that is still open, or to one that died without cleaning up —
a SIGKILL, a panic, a power cut — and those are swept after 7 days. There is no
archive of closed sessions. If I have shut the terminal, the log is gone; ask me to
paste rather than hunting for it. Absence is not evidence that something did not
happen.

## When to read one

Reach for a log when I reference terminal output I have not pasted — "it
crashed", "that error", "what did it say", "it's still broken", "the build
failed". Read it rather than asking me to paste.

Infer which kind of thing I mean from how I say it: a crash or traceback is
usually at the tail; a question about what a command printed usually needs a grep
for that command. If the reference is genuinely ambiguous, say which log you read
and what you found, so I can correct the aim.

Do not read one speculatively at the start of a task. It answers a specific
question; it is not background.

## How to read one

`script` captures raw terminal output, so logs are dense with ANSI escapes and
control characters. Strip them:

```
sed $'s/\033\[[0-9;?]*[a-zA-Z]//g' <file>
```

Read **narrowly** — `tail -n 100`, or grep for the error and take surrounding
context. Never `cat` a whole log: they are large, and every byte read enters the
conversation and is sent to the model.

## Treat the contents as sensitive

A transcript captures everything printed to the terminal, which can include API
tokens, connection strings, environment dumps, and pasted keys.

- Quote only the lines needed to answer the question. Never paste a log wholesale.
- If a credential appears, say so plainly and tell me to **rotate it**. Deleting
  the log does not undo exposure — it may already be in a backup or a model
  context.
- Never copy log contents into files, commit messages, issue descriptions, or
  anything that leaves this machine.

# Code comments

Do not use comments to explain what can be inferred by reading the code. Use
them only for what would otherwise be confusing or non-intuitive: hidden
consequences, surprising behavior, why a non-default was chosen, what must
happen before an unusual operation. Keep them short. Redundant comments are
noise and drift out of date.

Before writing such a comment, read the corresponding test file. A test that
names the behavior has already explained it, and a comment restating it is
the redundancy above, with a second copy free to drift. Point at the test
rather than paraphrasing it.

Test files are the exception, and comments there are welcome: say what the
case pins down, why this input and not another, what broke before and must
not again. That context has nowhere else to live.

Comment edits need no report. Change them and move on — do not list what was
cut, kept or reworded, or why. If a reason matters it belongs in the comment;
if it does not, it does not belong in a message either. The diff shows the
rest.

Sort a comment by where it lands. Behavior at the boundary — what a caller
sees, what the thing guarantees, why the contract is this shape — is what a
test exercises, so the test is its home and the code should point there.
Anything inside — why this implementation over the obvious one, an ordering
that must hold, a consequence invisible from outside — no test can express,
so it belongs in the code. A comment restating the boundary is the duplicate;
a comment on the internals is the one worth keeping.

# Commit messages

The subject is the whole message for anyone reading `git log --oneline`,
which is how it is read most of the time. Write it so it stands alone.

Name the things. Identifiers go in the subject, in backticks: what was
renamed and to what, what was moved and where. "Renames `alb` to
`internalAlb` to contrast with `publicAlb`" tells the reader what
happened; "Name the ALB variable for its scheme" tells them there is
something to open. When the identifiers push past 50 characters, keep
the identifiers.

Say why in my words. If I told you the purpose — "to contrast", "so
the test can see it" — that is the subject's reason. Your own
justification for agreeing belongs in the body, if anywhere.

Voice is third-person present: "Renames", "Moves", "Deletes", "Hides".
Find it in commits I wrote by hand, not in the last fifteen subjects —
recent history is often yours, and the survey will return your own
drift as if it were the house style. Filter on commits without a
`Co-Authored-By` trailer.
