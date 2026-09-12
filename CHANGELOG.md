# Changelog

All notable changes to this project, **directly impacting users** or
**downstream developers**, are recorded here; changes impacting a person or
persons who will use the final produced binary or binaries in any noticable
manner are logged and scoped to a release version.

The format is [Keep a Changelog 1.1.0](https://keepachangelog.com/en/1.1.0/) and
the version numbers follow [Semantic Versioning 2.0.0](https://semver.org/spec/v2.0.0.html).

## What is logged

A change is notable when a user of the produced binaries could notice it
without reading the source. New or altered behaviour, new or removed build
options, changed defaults, supported-platform changes, etc.

Refactors, formatting, test-only changes, CI configuration, and internal
build-system work does not get logged here. The git history records those
commits. However, a refactor that changes observable behavior is a behavior
change, and is logged as such.

## Who logs it

The author of the change, in the **same pull request** that makes the change.
*Reviewers* treat a missing enty the same as a missing test: a reason to
request changes.

## When to log it

**At the time the change is written**, not at release time. Reconstructing a
release's worth (or commits worth) of log entries from commit message entries
will simply produce logs less descriptive and reliable than the git commit
messages themselves, exactly what is trying to be avoided.

## Where to log it

Under the `## [Unreleased]` section, in the sub-section that accurately
describes the change. *For example*, a bug that was fixed without adding new
"maningful logic" (explained below) belongs under `### Fixed` and **should** be
tracked. **Meaningful logic** is any piece of *code* exposing new business
logic or functionality:

| Sub-section | Use for |
| :-- | :-- |
| `### Added` | New functionality. |
| `### Changed` | Altered behaviour of existing functionality. |
| `### Deprecated` | Functionality still present but slated for removal. |
| `### Removed` | Functionality deleted in this release. |
| `### Fixed` | Bug fixes that add no meaningful logic. |
| `### Security` | Vulnerabilities addressed. |

## Why it matters

A changelog is written for users/people who consume the project, so that (for
example) when they are deciding whether to upgrade, doing so and it failing,
and then finding out what changed causing it to break after upgrading, does not
require reading diffs. Semantic Versioning tells a consumer that a release is
is breaking; only the changelog tells them *what* broke and what to do about
it.

## How to log it

One entry per change, as a Markdown list item under the appropriate
sub-section. Write a complete sentence in the **past tense**, ending in a
period, and describing the effect on the user instead of the implementations
introduced:

```markdown
## [Unreleased]

### Added

- Added `--strict` to reject malformed input instead of repairing it.

### Fixed

- Fixed a crash when the input file was empty. ([#42](...))
```

Reference an issue and/or pull request where one exists. Delete any sub-section
that has no entries at release time; empty headings in a published release are
a waste of space and makes the document harder to follow.

## How to *cut* a release

Replace the `[Unreleased]` heading with the version and the release date in
`YYYY-MM-DD` form, keeping the brackets, then add a fresh
`[Unreleased section]` above it:

```markdown
## [Unreleased]

## [1.0.0] - 2026-09-02
```

Newest releases are placed at the top. Each release version is linked to the
GitHub repository tag it belongs to.

---

## [Unreleased]
