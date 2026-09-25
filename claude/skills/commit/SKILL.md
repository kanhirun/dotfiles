---
name: commit
description: Split a working tree into coherent commits and write their messages. Use when committing changes, staging work, deciding how to break up a diff, or writing a commit message. Produces history that git-bisect can actually use.
---

# Commit

Two requirements, enforced in different places. Do not conflate them.

- **Cohesion** — one commit does one thing. Makes history *readable*. This skill's job.
- **Bisectability** — every commit builds and passes tests. Makes history *mechanically usable*. The **pre-commit hook's** job.

A skill that only writes tidy messages does nothing for `git bisect`. Treat the hook as the correctness gate and never route around it.

## Procedure

### 1. Survey

```
git status
git diff                      # unstaged
git diff --cached             # staged
git log -15 --format='%s'     # message style in THIS repo
```

The last one is not optional. Match the repo's existing voice rather than importing a convention. Many repos use third-person present ("Adds X", "Fixes Y"), not the imperative mood a generic skill would impose. Read before writing.

### 2. Partition

Split the tree into commits. Rules, in priority order:

1. **Mechanical never rides with semantic.** A move or rename in the same commit as a behavior change makes the diff unreadable and, when bisect lands there, ambiguous. Extract first, change second — two commits.
2. **An enabling refactor precedes the feature that needs it.**
3. **Unrelated fixes split out**, even one-liners that happened to be sitting in the tree.
4. **Dependency order.** If B does not build without A, A comes first. This is what makes each commit independently valid.

**Show the proposed partition before creating anything.** The split is a judgment call and the user owns it.

If the tree genuinely cannot be cleanly partitioned — changes are entangled such that no ordering builds — say so and propose the smallest honest split, rather than inventing one that fails at commit time.

### 3. Stage and commit, one at a time

Path-based staging where the split is clean; `git add -p` where a single file holds hunks belonging to different commits.

Commit each one before staging the next. The hook verifies each as it is created, so a failure tells you exactly which partition was wrong while the rest is still uncommitted.

### 4. Message

The shape is git's own 50/72 rule (git-commit docs, Tim Pope's post):

- **Subject**: one line, capitalized, no trailing period, under ~50 characters. What changed, in the repo's established voice.
- **Blank line**, then the body wrapped at 72. Git never rewraps: a longer line is shown as-is in `git log`, and a missing blank line makes git treat the whole thing as the subject.
- **Body**: *why*. The diff already shows how. Skip the body only when the subject is genuinely complete.
- **Name the observable behavior change.** When bisect fingers this commit, the body should say what to look at without reading the diff. This is the single highest-value habit for debuggability.
- **`Fixes` opens a subject only when the defect is already on master.** It says the bug shipped and this commit is the repair. A defect introduced on this branch is a fixup instead (below), and the rebase folds it into the commit that caused it.

#### Showing the error

Someone hits the bug, searches for what they saw, and should land on the commit
that fixed it. Put the error where that search will reach.

- **Subject: the error's shortest identifying form.** The exception class, the
  error code, the distinctive phrase — `Fixes DeploymentError on the public
  ALB's port 80 listener`, not `Fixes the listener collision`. The name alone
  goes in; it shares the ~50 characters with what changed.
- **Body: the error as it appeared**, indented as a block, above the
  explanation. Say where it came from — the job, the test, the command — so the
  whole thing can still be found.
- **Truncate to what identifies it.** The message and the frame naming your own
  code earn their place; the library internals under it do not. Mark a cut
  `[…]`.
- **Cut what will not recur.** Request ids, timestamps, runner paths and
  generated ARNs date the commit and match nothing later.
- **No error, no block.** A bug that produced wrong output rather than a failure
  gets observed-versus-expected instead. Do not manufacture an error to fill the
  shape.

The content rule is Linus's, repeated across the kernel lists: a descriptive summary plus a body that explains the reasoning. "Fix bug", "Update code", "Address review comments" name no change and no reason, and are what a reviewer or a bisect will find. A subject should let someone skim `git log --oneline` and know what each commit did; the body should let them know why it was done that way and not another.

## Fixing an earlier commit on this branch

When a change corrects a defect introduced by an earlier commit that has **not yet reached main**, it does not belong in a commit of its own. A standalone fix leaves the original commit broken permanently, so every bisect landing in the range between them finds a bug that was already known and already fixed. That is noise the history should not carry.

Record it as a fixup:

```
git commit --fixup=<sha>
```

### Finding the target

Identify the commit that introduced the line being corrected, then confirm it is still rewritable:

```
git blame -L <start>,<end> -- <file>        # who introduced this
git log -S'<the broken code>' --oneline     # or search by content
git log origin/main..HEAD --format='%h %s'  # the range that may be rewritten
```

If the target is not in that last range, it is already upstream. Then it is **not** a fixup — write an ordinary commit whose subject opens with `Fixes` and names the defect, with a body saying why the earlier commit was wrong. Master is the only place a bug can have been hit, so it is the only place `Fixes` is honest.

### Stop at the fixup

**Do not run the rebase.** `git rebase -i --autosquash <base>` is the user's call: it rewrites history, it can conflict, and the right moment depends on whether they are about to push, review, or hand the branch to someone else.

Create the fixup, then tell them plainly:

- which commit it targets,
- the exact base to autosquash from,
- what the history will collapse to.

Give them a decision to execute, not one to reconstruct.

### What a fixup does and does not buy

The fixup commit is a real commit and the hook tests it like one, so it must build on its own. But **the range is not bisectable until the squash happens** — until then the original commit is still broken and still in history. A fixup records an intention; the rebase is what delivers the property.

## Verifying a range after the fact

The hook protects commits made *through* it. History that was rewritten, rebased, or committed with `--no-verify` has no such guarantee. To audit a range:

```
git rebase --exec '<build and test command>' <base>
```

Runs the command at every commit and stops at the first failure. Use it after any history rewrite, and before pushing a branch that will be bisected later.

## Hard rules

- **Never `--no-verify`.** The hook is the bisectability guarantee; bypassing it silently poisons every future bisect through that range. If the hook is wrong, fix the hook.
- **Never commit a known-broken intermediate state**, even with a "fixed in next commit" note. That is precisely the range bisect cannot cross.
- **Never rewrite pushed history** without being asked.
- **Never run `--autosquash` unprompted.** Creating the fixup is this skill's job; collapsing it is the user's.
- **Never fix up a commit that is already upstream.** Check `git log origin/main..HEAD` before reaching for `--fixup`.
- **Never commit unrelated changes together** because they happen to be in the tree. That is what the partition step exists to prevent.
- **Do not commit at all unless asked.** Staging and proposing a partition is the default; creating commits is not.

## Linear issue ids

The merge commit already carries the issue id. An id repeated on every commit
in the branch is therefore redundant, and worse: it claims each commit did
the issue's work when most of them did not.

**Put an id on a commit only when that commit meets the issue's goal.** Use
Linear's magic-word form, appended to the subject line:

```
Verify real Clerk sessions in staging, fixes DEV-1370
```

The annotation counts toward the subject length, so leave room for it.

`fixes` for a bug, `resolves` for anything else. Every other commit on the
branch carries no id at all — not in the subject, not in the body. A subject
already opening with `Fixes` still needs the trailing magic word: Linear reads
the annotation, not the verb.

### Judging "meets the goal"

Read the issue, not the branch name. The test is whether merging this commit
alone would let you close the issue.

- A refactor, a rename, a comment pass, a cleanup of now-dead arguments —
  none of these resolve anything, however necessary they were.
- Foundation that "adds nothing to any caller yet" does not resolve the
  issue the caller will eventually satisfy.
- Where the issue describes something a user can observe, the id belongs on
  the commit that makes it observable. A backend change behind an unshipped
  UI does not resolve it; the frontend commit that integrates it does.
- If the issue lists several complaints and the branch answers only some,
  no commit gets the id. Annotating would auto-close work that is not done.
  Say so and let the user close it by hand.

When in doubt, leave it off. A missing id costs one manual close; a wrong
one closes an open bug silently.
