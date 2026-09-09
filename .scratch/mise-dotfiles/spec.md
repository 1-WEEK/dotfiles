# Replace Dotter with native mise dotfiles management

Status: implemented

## Problem Statement

The repository uses mise for tools but requires Dotter separately for configuration deployment. Maintaining two systems introduces duplicated configuration and installation work when preparing macOS, Raspberry Pi, and WSL2 machines.

The current deployment check only checks the selected Dotter packages, so missing or incorrect links can remain unrepaired. Existing-file backups use fixed names and a separately maintained target list. Fish functions are linked as an entire directory even though Fisher also writes plugin functions there. Replacing Dotter must address these migration boundaries without losing machine-local configuration.

## Solution

Use native mise dotfiles declarations alongside tool declarations in the global mise configuration. Keep the existing machine setup workflow, replacing its Dotter integration and adjusting prerequisite ordering as needed. Provide configuration deployment through native mise commands wherever they cover the agreed behavior.

Use one fixed checkout location and require the latest mise. Support both a new machine and an existing Dotter-managed machine. Preserve correctly linked files, report conflicts before changing deployment targets, and offer explicit backup-and-adopt behavior. Keep repository-owned Fish functions alongside locally installed plugin functions.

## User Stories

1. As a maintainer, I want tools and dotfiles declared together in mise, so that I maintain one configuration management system.
2. As a maintainer, I want native mise capabilities used directly, so that I avoid maintaining equivalent custom wrappers.
3. As a new-machine user, I want setup to establish configuration from the standard checkout location, so that installation is repeatable.
4. As an existing user, I want to migrate from Dotter, so that I can adopt mise without rebuilding my machine.
5. As a macOS user, I want my existing selected configuration, including Ghostty, deployed, so that migration preserves my environment.
6. As a Raspberry Pi user, I want the existing platform configuration preserved, so that this migration does not remove my setup path.
7. As a WSL2 user, I want the existing platform configuration preserved, so that migration keeps my environment usable.
8. As a Linux user, I want macOS-only configuration excluded from deployment, so that unrelated targets are not created or modified.
9. As a user, I want setup to install or upgrade mise to the latest release, so that deployment never proceeds with an outdated prerequisite.
10. As a user, I want prerequisite failures to stop configuration deployment, so that failures do not lead to a misleading successful setup.
11. As a user, I want correctly linked files reused, so that migration does not unnecessarily replace working configuration.
12. As a user, I want repeat deployment to leave correct targets unchanged, so that rerunning setup is routine.
13. As a user, I want missing and incorrect targets detected from actual deployment state, so that old setup metadata cannot hide configuration drift.
14. As a user, I want all detected target conflicts reported before deployment changes those targets, so that I can choose how to resolve them.
15. As a user, I want ordinary deployment to stop on conflicts, so that existing configuration is not overwritten implicitly.
16. As a user, I want an explicit backup-and-adopt option, so that I can switch conflicting targets to repository-managed configuration.
17. As a user, I want earlier backups preserved and new backup locations reported, so that I can recover configuration after migration.
18. As a Fish user, I want custom functions linked individually, so that Fisher-generated functions can coexist with them.
19. As an existing Fish user, I want migration away from a directory link to preserve existing function content, so that plugin installation and local edits are not lost.
20. As a user, I want machine-local mise configuration preserved, so that personal host-specific tools remain local.
21. As a Manico user, I want the existing preference-import approach retained, so that device-specific and license-bearing preferences are not turned into shared linked files.
22. As a user, I want to preview deployment without changing configuration, so that I can review its effects first.
23. As a user, I want to redeploy configuration without reinstalling unrelated software, so that everyday updates remain focused.
24. As a maintainer, I want repository Dotter dependencies and deployment instructions removed, so that future setups do not keep requiring Dotter.
25. As an existing user, I want manual cleanup instructions for the old Dotter installation and state, so that I can retire them after verifying migration.
26. As a user, I want an occupied standard checkout location reported rather than overwritten, so that adopting the location convention does not destroy another checkout or directory.

## Implementation Decisions

- Keep configuration deployment as one part of machine setup, using the domain glossary's distinction. Do not migrate the entire machine setup workflow to mise bootstrap.
- Put tool and dotfiles declarations in the global mise configuration. Do not introduce an independent deployment manifest as the primary design.
- Resolve deployment sources through the agreed fixed checkout location, including initial establishment of the global configuration itself. Do not silently move an existing checkout or overwrite a directory occupying that location.
- Prefer native mise deployment, inspection, and preview capabilities. Add narrowly scoped orchestration only for verified gaps in the agreed prerequisite, conflict, or backup behavior; do not recreate native features.
- Update the mise installation step, configuration deployment step, relevant profile ordering, package dependencies, and user documentation. Preserve existing platform selection and the current macOS-only Ghostty selection.
- Require the latest mise rather than accepting an older minimum supported version. Treat latest stable as the working interpretation recorded below. Check and install or upgrade before configuration deployment; stop deployment if verification or upgrade fails.
- Ensure deployment prerequisites also apply when the existing step-selection interface requests deployment alone. The current runner continues after failed steps, so a failed mise prerequisite must not permit dependent deployment to execute.
- Use native dotfiles-only deployment for routine configuration updates rather than invoking unrelated machine setup operations. Determine how the latest-version requirement is enforced for this entry point without adding an equivalent deployment wrapper.
- Base deployment satisfaction on actual targets and sources, not on the presence of a generated package-selection file. Correct links are already satisfied; missing targets require deployment; links to other sources are conflicts.
- Preflight the selected targets before modifying them. Default conflict handling is a reported non-success result without overwriting targets. Automatic setup mode does not itself authorize backup-and-adopt behavior.
- Provide explicit backup-and-adopt behavior for conflicting regular files, directories, and links. Preserve earlier backups, report backup locations, and stop rather than replace a target whose backup failed. A full transaction across all targets is not required by this design.
- Link repository-owned Fish functions individually. Preserve unmanaged neighboring functions and handle an existing whole-directory link without deleting its source directory or its contents.
- Preserve machine-local mise overrides and the separate Manico preference-import workflow. Do not extend deployment ownership to generated completions, caches, credentials, or plugin-generated configuration.
- Remove repository Dotter declarations, installation dependencies, installer steps, profile integration, deployment calls, and obsolete operational documentation. Retain historical references in this specification where they explain the migration.
- Leave installed Dotter binaries and machine-local Dotter state untouched. Document manual cleanup after successful verification.

## Testing Decisions

- Confirmed primary test boundary (2026-09-10): the existing machine setup command selecting configuration deployment, observed through exit status, diagnostics, resulting links and file contents, and backups. Exercise the documented native deployment command against the same fixtures where needed.
- Test observable outcomes rather than helper structure, literal declaration lists, step numbers, or implementation-specific command sequences. Prefer one integration fixture around deployment over new internal test interfaces.
- Isolate the home directory, mise configuration, state, and data, and the standard checkout location beneath the temporary home. Never deploy test fixtures into the user's real home or change their global trust state.
- Cover an empty target environment, adoption of correct Dotter-created links, missing-link repair, repeat deployment, conflicting files and foreign links, explicit adoption, backup preservation, and backup failure.
- Verify that default conflict handling does not modify deployment targets, and that explicit adoption preserves recoverable content before replacing each target. Do not infer all-or-nothing rollback from preflight behavior.
- Cover Fish functions with existing plugin neighbors and migration from a whole-directory link, asserting preservation of both repository sources and unmanaged function content.
- Exercise macOS, pi4, and wsl2 selection through the existing profile interface. Verify platform-specific target behavior without treating a simulated profile on macOS as proof of native Linux execution.
- Cover absent, outdated, and current mise, release-check failure, and upgrade failure with controlled external-command responses. Verify that both normal setup and deployment-only selection respect the prerequisite. Avoid depending on a changing public release or installing the global tool inventory in tests.
- Verify setup preview and native deployment preview leave deployment targets and backups unchanged. Cover machine-local mise overrides and unrelated Manico preference content remaining intact.
- Prior art: the inspected repository has a step-selecting setup interface and documented preview/list workflows, but no existing automated test suite was found. Reuse those external interfaces; add only the fixture support needed to run them in isolation.
- Complete shell/configuration validation appropriate to changed files and inspect remaining Dotter references for obsolete operational use. Do not add tests whose sole purpose is asserting removal of old text.

## Out of Scope

- Applying configuration to the current machine or committing as part of this specification-publication task. Implementation is described here for subsequent work and is not performed by publication.
- Migrating all software installation, services, or machine setup responsibilities into mise bootstrap.
- Supporting arbitrary deployment checkout locations or silently relocating existing checkouts.
- Automatically uninstalling Dotter or deleting its machine-local state and caches.
- Introducing automatic dotfile history, background synchronization, a new secrets system, or additional platform profiles.
- Redesigning shell configuration, fixing unrelated Manico setup behavior, or changing the global tool inventory.
- Supporting outdated mise through a fallback deployer.

## Further Notes

- The agreed standard checkout location is `~/.dotfiles`. The current development worktree is not that deployment location and must not be moved as part of writing or implementing the change.
- Preserve the host-owned `~/.config/mise/config.local.toml` file.
- Latest stable, checked at execution time with verification or upgrade failures blocking deployment, is the stated interpretation of the user's requirement to force the latest mise. No offline fallback has been agreed.
- The inspected local mise version is 2026.9.3 and exposes native dotfiles commands. This observation does not pin the required version or prove that every desired migration behavior is native.
- Implementation must verify source resolution for self-managed global configuration, platform selection, directory-link migration, and latest-version enforcement against the version actually used. If a native capability cannot meet the specification, surface the concrete gap instead of silently weakening the requirement.
- Relevant primary references: [mise dotfiles](https://mise.jdx.dev/dotfiles.html), [mise configuration](https://mise.jdx.dev/configuration.html), and [mise installation](https://mise.jdx.dev/installing-mise.html). These are references from the design investigation, not a substitute for implementation verification.
- This specification is published to the repository's local Markdown issue tracker under its canonical ready-for-agent status. Publication does not start implementation or deployment.

## Implementation record

Implemented after publication, with command-level test coverage approved on 2026-09-10. Native mise declarations, platform selection, pre-deployment version/conflict hooks, explicit backup adoption, and setup integration replace Dotter. See [migration instructions](../../docs/dotfiles-migration.md).

Validation: 14 isolated command-level integration tests with mise 2026.9.3, shell syntax checks, and `git diff --check`. Linux profile selection was simulated on macOS; native Linux execution remains unverified. Configuration was not deployed to the current machine.
