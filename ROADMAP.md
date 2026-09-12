# Roadmap

This file provides an overview of the direction this project is heading,
this includes future goals and tasks needed to be completed to move forward in
development.

### Example:

The roadmap is organized in steps that focus on a specific theme, for example
UX:

```markdown
## [M1 - Basic Infrastructure](https://github.com/Dovyski/template/milestone/1)

In this phase of the project the focus is on X, Y and Z. The expected features are:

### [I1 - Implement this thing](...)

- Something the user can do.
- Description of a feature.
- Ability to save things.
- Etc.

### [I2 - Documentation for here](...)

- What is it about.
- Why the documentation.
- Etc.

## [M2 - User Experience](https://github.com/Dovyski/template/milestone/2)

In this phase of the project the focus is on A, B and C. The expected features are:

- Something the user can do.
- Description of a feature.
- Ability to save things.
- Etc.
```

## [M1 - Finish Build, Move to SQLite3](https://github.com/cooldood155/end-to-end-sqlite3-in-c/milestone/1)

The goal of this milestone is to fully complete the projects *build* workflow.
The tools needed to be simplified for this project are Conan2 and CMake.

- CMake automatically detects newly added or updated source files for
  **registered targets** of the following *types*:

  - libraries (static or shared or both, header only, source only, or settings
    only interfaces).
  - applications.
  - tools.
  - tests.
- Conan2 installs project dependencies, CMake configures and builds the project
  for any of requested target system(s) via simple command line driver.
- Script to clean/remove all build generated output.
- Conan2 profiles easily generatable via command line driver.
- Continuous Integration implemented to use the previously mentioned command
  line tool(s) and surface possible issues across different systems.

### [I1 - CMake Module Interface and Verification Scripts](https://github.com/cooldood155/end-to-end-sqlite3-in-c/pull/4)

*Mistakenly not created as an official issue, but rather a pure PR.*

- Remove the need to manually update CMake files per-directory when adding new
  sources to an already defined library or executable.
- Fixed many bugs that were exposed while developing, as well as *known bugs*
  that were only present due to a lack of functionality not yet implemented.
- Introduces a central verification script meant to be ran locally and by CI
  agents; two helper scripts to register supported native and cross build
  targets and provide all of the underlying functionality to probe the targets
  requested.
