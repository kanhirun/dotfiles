---
name: pr
description: Open a pull request whose body someone in QA, product or support can act on — what the change is and how to try it — while the commits carry the engineering detail. Use when opening a PR, drafting or rewriting a PR description, or checking whether a branch is fit to review.
---

# Pull request

Two audiences, two channels. Do not let them bleed.

- **The commits** are for whoever reads the diff. They already carry the
  step-by-step and the reasoning. The `commit` skill owns them.
- **The body** is for everyone else — QA who has to test it, a PM who has to
  say what shipped, whoever fields the customer question. It answers what this
  is and how to check it, and nothing a commit already said.

A body that restates the commits is the same duplication a redundant code
comment is, with the same failure: two copies, one of which goes stale.

## 1. Gate before writing

A PR is an outward-facing act. Check first, in this order, and stop at the
first failure rather than opening something a reviewer will bounce:

```
git log origin/master..HEAD --format='%h %s'   # partitioned? ids right?
git status --short                             # nothing stranded
<the project's test command>                   # green at HEAD
git fetch origin && git log --oneline HEAD..origin/master   # behind?
```

- **Red suite → stop.** Say which tests and stop. Never open a PR on red.
- **Unpartitioned commits → stop.** A mechanical rename riding with a
  behaviour change is unreviewable; that is the `commit` skill's job, done
  before this one starts.
- **Behind master → say so.** Rebasing is the user's call, not this skill's.
- **Uncommitted changes → stop.** Either they belong in the PR or they do not;
  both answers need the user.

## 2. Title

**The title is the Linear issue's title, verbatim.** Take the id from the branch
name (`kel/dev-1370-…`) or from what the user says, and read the issue with
Linear's `get_issue`. Never reconstruct it from the branch slug — that has been
lowercased and hyphenated and has already lost the wording.

One title in both places is how anyone moving between Linear and GitHub knows
they are looking at the same work. Two spellings of one change is a question
every reader has to resolve alone, and the PR is the copy that gets linked into
Slack.

The id is still appended; matching means the title text matches, not that the
line is byte-identical:

```
Access Pillar on Staging using Clerk sign-in, fixes DEV-1370
```

### When the issue's title does not fit

The rules below are the bar. A Linear title often fails them — issues get
written in a hurry, in the system's vocabulary, before the shape of the fix is
known. **Do not quietly reword it, and do not quietly ship a title that names a
construct or an environment. Stop and ask.** Three answers, and the choice is
the user's:

- use the issue's title as it stands, mismatch resolved in its favour;
- use the better title and edit the Linear issue to match, so the two agree;
- use the better title and leave the issue alone, accepting the divergence.

Quote both titles when asking. The difference is usually obvious once they are
side by side, and the user picks in one word.

With no linked issue, write the title from the rules below and say there was
none to match.

### What a good title looks like

The title belongs to the body's audience, not the commits'. It is the one-line
form of *What this is* — the capability a reader gains, in words they already
have. It should read like the test case QA is about to run.

```
Access Pillar on Staging using Clerk sign-in
```

Not `Opens staging past the tailnet, with Clerk as the gate`. That is a commit
subject wearing a title's clothes: it describes what the change did to the
system, in the system's own vocabulary.

- **Name the product**, not the environment alone — "Pillar on Staging", not
  "staging".
- **State the new capability**, not the removal of the old constraint. Someone
  who never knew about the tailnet should not have to learn about it to read
  the title.
- **No implementation vocabulary, and no identifiers.** Construct names, load
  balancer schemes and architectural roles belong in the commits. A backtick in
  a PR title is a smell.
- **Name the mechanism the tester will see.** "Clerk sign-in" is a screen you
  land on; "Clerk as the gate" is a role in a diagram.
- **One clause.** A comma appending the mechanism is the commit habit returning.

The title is also the id-bearing line — Linear reads it, and for a squash merge
it becomes the subject on master. `fixes` for a bug, `resolves` for anything
else. The judgement of whether the
branch *meets the issue's goal* is the same one the `commit` skill makes, and
it is stricter than it looks: if the issue lists several complaints and the
branch answers some, **no id goes on the title**. Say so, and let the issue be
closed by hand. A missing id costs one manual close; a wrong one silently
closes a live bug.

## 3. Body

Four parts, in this order. Omit one only when it is genuinely empty, and say
that it is rather than dropping the heading silently.

### What this is

One to three sentences, in language someone outside the team can repeat. What
a person can now do that they could not, or what stopped being broken. No file
paths, no class names, no "refactors the X layer".

The test: hand it to someone who has never opened the repo. If they cannot
tell what changed for them, it is not written yet.

### How to test

Numbered steps, runnable by someone who does not have the branch checked out.
Real URLs, real data, and what to expect at each step — not "verify it works".

**Only a step you have actually run goes here.** This is the rule the section
lives or dies on. Anything you could not exercise is named in the body, in
plain sight:

```
Not verified: signing in end to end — I only confirmed the page loads.
```

QA can plan around a stated gap. They cannot plan around a step that was
guessed and fails at their desk.

For anything with a screen, say what it looks like, or say `No visual change.`

### Not in this change

The deliberate gaps and the live risks, so QA does not file them as bugs and
nobody promises them onward. Where a follow-up is intended, say that; where
something is knowingly left ugly, say that too.

### Detail

One line pointing at the commits, and where to start. Never a bullet per
commit — GitHub already renders that list, and a hand-copied one drifts the
moment a commit is amended.

## 4. Open it

```
git push -u origin <branch>
gh pr create --title '<title>' --body-file <file>
```

Write the body to a file rather than inlining it: backticks and `$` in a shell
string will bite. Then report the URL and the one thing a reviewer should look
at first.

**Stop there.** Merging is never this skill's call, and neither is requesting
review from a particular person.

## Revising an existing PR

`gh pr edit --body-file` replaces the body wholesale, so read the current one
first — a bot may have appended to it, and a blind replace eats that.

```
gh pr view <n> --json body --jq .body
```

## Hard rules

- **Never open a PR on a red suite.**
- **Never write a test step you have not run.** Label the gap instead.
- **Never restate a commit body.** If it is in a commit, link, do not copy.
- **Never merge**, and never mark ready-for-review, without being asked.
- **Never put the Linear id on a title** whose branch answers only part of the
  issue.
- **Never invent a title when the branch has an issue.** Read the issue, use its
  title, and ask when it does not fit rather than choosing for the user.
- **Never paste a credential, token or connection string into a body.** The PR
  is more widely readable than the terminal it came from, and edits do not
  unsend it.
