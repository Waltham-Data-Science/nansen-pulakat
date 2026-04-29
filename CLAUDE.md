# CLAUDE.md

Guidance for future Claude Code sessions working on **nansen-pulakat**. Read
this before exploring — it summarises three coupled repos so you don't have
to rediscover the structure each session.

---

## What this repo is

`nansen-pulakat` is a MATLAB data-management application for the Pulakat lab.
It is **not** a standalone tool: it stitches together two upstream
frameworks and adds the lab-specific glue and GUI extensions.

```
              +-----------------------------+
              |        nansen-pulakat       |
              |  (this repo: integration +  |
              |  lab GUI extensions)        |
              +---+---------------------+---+
                  |                     |
                  v                     v
       +---------------+         +-------------------+
       |    NANSEN     |         |    NDI-matlab     |
       |  (GUI / app   |         |  (database +      |
       |   framework)  |         |   cloud sync)     |
       +---------------+         +-------------------+
```

| Repo                     | Role                                                      | Upstream                                          |
|--------------------------|-----------------------------------------------------------|---------------------------------------------------|
| `nansen-pulakat`         | Integration layer + Pulakat-lab GUI extensions + installer | `Waltham-Data-Science/nansen-pulakat` (this)      |
| NANSEN (GUI framework)   | App shell, metadata tables, plugin loader                  | `VervaekeLab/NANSEN` — track **`dev`** branch     |
| NDI-matlab (DB/cloud)    | Dataset model, document store, NDI cloud sync              | `VH-Lab/NDI-matlab`                               |
| openMINDS_MATLAB         | Ontology types used by NDI                                 | `openMetadataInitiative/openMINDS_MATLAB`         |

The client deployment workflow: a researcher runs `install.m`, which clones
all of the above into `~/ndi/tools/`, wires up MATLAB paths, and launches
the NANSEN GUI configured for the `pulakat` project.

---

## Where to find each repo locally

When developing in this environment, all three repos are checked out as
siblings and you can read them directly:

```
/home/user/nansen-pulakat   <-- this repo
/home/user/Nansen           <-- VervaekeLab/NANSEN (dev branch)
/home/user/NDI-matlab       <-- VH-Lab/NDI-matlab
```

If you need to understand a NANSEN abstract class, an NDI cloud call, or
how a plugin is discovered, **read those repos directly** — don't re-clone
or guess. They are the source of truth for behaviour you can't change.

---

## Layout cheat sheet

```
nansen-pulakat/
├── install.m                          # Single entry point for fresh installs
├── README.md                          # User-facing setup instructions
├── src/
│   ├── ndi/+ndi/                      # Integration layer (re-uses ndi.* namespace)
│   │   ├── +nansen/
│   │   │   ├── startup.m              # Main runtime entry: cloud sync + GUI
│   │   │   ├── +sync/{repo,status}.m  # Git clone/pull wrapper used by install + startup
│   │   │   ├── +fun/                  # Helpers: runTagged, getIdentifier, GUI dialogs,
│   │   │   │                          #   metatable utilities, cloud-status checks
│   │   │   ├── +import/               # Session/Subject/File importers + validators
│   │   │   ├── +metatable/            # Edit/merge/remove/update operations
│   │   │   └── +export/               # Metadata + generic-file exporters
│   │   └── +setup/+conv/+pulakat/     # Per-project conversion config
│   │       ├── project_info.json      # Cloud dataset ID, repo URL, paths
│   │       └── +fileType/             # Lab file-type parsers
│   └── pulakat/                       # Lab-specific NANSEN module
│       ├── code/+pulakat/
│       │   ├── module.nansen.json     # NANSEN module manifest (Name, Description)
│       │   ├── startup.m              # Thin wrapper -> ndi.nansen.startup('pulakat',...)
│       │   ├── +tablevariable/        # ~70 column definitions, auto-discovered by NANSEN
│       │   │   └── +{dataset,session,subject,file}/  # one .m per column
│       │   ├── +objectmethod/+{dataset,subject,file}/+methods/  # row-action methods
│       │   └── +sessionmethod/+methods/+{import,export}/        # session menu actions
│       ├── configurations/            # JSON + .mat: menu visibility, file-var config,
│       │                              #   pipeline + datalocation settings
│       └── metadata/tables/           # metatable_catalog.mat + column settings JSON
└── tests/+ndi/+unittest/+nansen/      # ~20 test classes (offline + cloud)
```

Two things to internalise:

1. **`+pulakat/+tablevariable/...` and `+pulakat/+{object,session}method/...`
   are discovered by NANSEN purely by folder/name convention.** No central
   registry. A typo in a class name or a missing file silently disappears
   from the GUI. Tests that exercise the column or method are the only
   safety net.
2. **The integration layer reuses `ndi.*`** (`src/ndi/+ndi/+nansen/...`).
   This sits next to upstream NDI-matlab on the path; both populate
   the `ndi` namespace. Don't add anything to `src/ndi/+ndi/` that
   shadows an upstream NDI function.

---

## Runtime flow

### Fresh install (client machine)
`install.m` is the only thing the user runs. It:

1. Checks for `git` on PATH.
2. Bootstraps `ndi.nansen.sync.repo` via `websave` if not yet on path.
3. Clones (in order) nansen-pulakat → NANSEN (`dev`) → openMINDS → NDI-matlab into
   `~/ndi/tools/` (overridable via the `codePath` arg).
4. Runs each upstream installer (`nansen_install`, openMINDS `setup.m`,
   `ndi_install`) inside `install_runTagged` so their output is grouped
   under `[Nansen Install]` / `[openMINDS Setup]` / `[NDI Install]`.
5. Strips stale pre-restructure pathdef entries (old `pulakat/code`,
   `pulakat/code-NDI`, etc.) before NDI's path-reset re-applies them.
6. `addpath(genpath(codePath))` and `savepath` to **`userpath/pathdef.m`**
   (matlabroot is often read-only).
7. Appends an idempotent pathdef-loader to `userpath/startup.m` so future
   MATLAB launches restore the saved path.
8. Calls `ndi.nansen.startup('pulakat', dataPath, 'SkipRepoSync', true)`.

### Subsequent launches
- A plain MATLAB restart auto-loads paths via the `userpath/startup.m`
  snippet — code is available but **no cloud sync happens**.
- `pulakat.startup` (or `ndi.nansen.startup('pulakat')`) is what actually
  syncs with NDI cloud and opens the GUI.
- Both support `Headless=true` for CI/scripting.

---

## Cross-repo coupling — what we depend on

These are the upstream surfaces that, if changed, will break us:

| We use                                              | Upstream defines                                |
|-----------------------------------------------------|-------------------------------------------------|
| `nansen.metadata.abstract.TableVariable`            | NANSEN — every `+pulakat/+tablevariable/*` subclasses it |
| NANSEN's plugin loader / module manifest            | NANSEN — `module.nansen.json` schema            |
| `nansen.ProjectManager`                             | NANSEN — used in `ndi.nansen.startup`           |
| `nansen` (the GUI launcher function)                | NANSEN                                          |
| `ndi.dataset.dir`                                   | NDI-matlab — top-level dataset object           |
| `ndi.cloud.{testLogin,uilogin,downloadDataset,sync.downloadNew,authenticate}` | NDI-matlab |
| `ndi_install`, `nansen_install`                     | both — invoked by `install.m`                   |

Because NANSEN's `dev` branch is what we pin, **upstream NANSEN changes
land in our installs immediately**. CI runs against `dev` to surface
breakage early.

---

## Conventions

### Tagged output ("Pattern B")

All status/warning/error output in the integration layer carries a
bracket prefix so a user can paste a single line and a developer can
grep straight to source.

- **Info lines** use a short module tag:
  `fprintf('[%s] message\n', infoTag)` where `infoTag` is e.g.
  `'NDI Startup'`, `'Pulakat'`, `'Install'`.
- **Warnings and errors** use a full MException-style ID and **embed
  that exact ID as a bracket prefix in the message**:

  ```matlab
  warning([funcId, ':CloneFailed'], ...
      '[%s:CloneFailed] Clone failed: %s', funcId, cmdOut);
  ```

  The printed prefix must match the throw identifier exactly. Don't
  print `[NDI:Nansen:Sync:Repo]` while throwing `:CloneFailed` — print
  `[NDI:Nansen:Sync:Repo:CloneFailed]`.

- **Multi-line / banner output** from upstream calls
  (`nansen_install`, openMINDS setup, `ndi_install`) is captured via
  `evalc` and re-emitted by `ndi.nansen.fun.runTagged` (and the local
  `install_runTagged` mirror in `install.m`). The first non-empty line
  gets the tag; subsequent lines are indent-aligned to the
  post-tag column. Lines matching `HidePatterns` are dropped — used
  to silence the openMINDS class-alias warning family.

When adding new code: pick a `funcId` at the top of the function and use
it for every warning/error/fprintf. See `src/ndi/+ndi/+nansen/+sync/repo.m`
or `install.m` for the canonical pattern.

### MATLAB docstring style

Every public function has a help block with `Inputs`, `Name-Value Pairs`,
`Outputs`, `Examples`, and `See also:` (uppercase function names).
Match the existing tone — see `ndi.nansen.startup` and `install.m`.

### MException ID namespace

- Integration layer: `NDI:Nansen:<Subsystem>:<Reason>`
  (e.g. `NDI:Nansen:Sync:Repo:CloneFailed`, `NDI:Nansen:Startup:NotAuthenticated`).
- Installer: `Install:<Reason>` (e.g. `Install:GitNotFound`).
- Pulakat layer: prefer `Pulakat:<Subsystem>:<Reason>`.

---

## Tests

Layout: `tests/+ndi/+unittest/+nansen/<TestClassName>.m`

Two CI tiers in `.github/workflows/matlab-tests.yml`:

- **Offline tests** (every push/PR): 17 test classes — project setup,
  metatable ops, file parsing, importers, sync. Run by listing class
  names in the workflow file.
- **Cloud tests** (gated on `NDI_CLOUD_USERNAME`/`NDI_CLOUD_PASSWORD`
  secrets): 3 test classes — `CreateDataset`, `Startup`, `ImportSession`.
  Skipped with a notice when secrets aren't configured (e.g. on PRs from
  forks). Cloud env defaults to `prod`; override with `CLOUD_API_ENVIRONMENT`.

CI also pre-clones DID-matlab, vhlab-toolbox-matlab, and mksqlite
(building the MEX with `buildit.m`), because NDI's database backend
dispatches through `did.implementations.sqlitedb`.

Local run (rough): `addpath(genpath('src')); addpath(genpath('tests')); runtests('tests/+ndi/+unittest/+nansen')`
after the upstream repos are on the path.

**Plugin smoke test**: `ndi.unittest.nansen.ModulePlugins` discovers
every NANSEN module under `src/*/code/+*/module.nansen.json`, walks
each module's `+tablevariable` / `+objectmethod` / `+sessionmethod`
subtrees, and emits one parameterised test case per file. It catches
syntax errors, missing parent classes, broken abstract-property
contracts, and methods that have lost the no-arg `fcnAttributes`
branch — failure modes that would otherwise only surface when a user
clicks into the GUI. Module-agnostic, so a fork that adds a second
`+labname` package gets the same coverage for free.

---

## Branching and commits

- Default working branch for Claude sessions:
  `claude/<short-task-name>-<random-suffix>` — never push to `main`
  without explicit user instruction.
- Commit messages: short imperative subject (no trailing period).
  Body is optional but expected for non-trivial changes — explain the
  *why*, not the *what*. See `git log --oneline` for tone.
- Existing tone uses single-quoted MATLAB function names in subjects
  (e.g. "Apply pattern B to src/pulakat and align tests").
- Don't bypass hooks (`--no-verify`) or amend pushed commits without
  asking.

---

## Deployment / smoke-test gotchas

Things to verify before handing a build to a client:

1. **`install.m`'s websave bootstrap fetches `repo.m` from `main`.**
   If we rename or move `src/ndi/+ndi/+nansen/+sync/repo.m`, fresh
   installs from a previously-downloaded `install.m` break. Update
   the URL there and the README's MATLAB-paste snippet together.
2. **NANSEN tracks `dev`**, not a tag. Upstream churn there is the
   most likely source of regression. CI offline-tests catch most.
3. **openMINDS class-alias warnings are benign** but loud. They are
   suppressed via `HidePatterns` in three places (`install.m`,
   openMINDS `setup.m`, NDI-matlab installer). If a fresh install
   spams `cannot be used as an alias for more than one class`,
   the suppression list lost coverage.
4. **`+pulakat` plugin discovery** is name-convention based.
   Adding/renaming a tablevariable or method requires no registry
   edit, but also has no compile-time check. Run the GUI after any
   such change.
5. **`userpath/pathdef.m`** is the persisted path. If the client's
   installer path differs from the one baked into `pathdef.m`, paths
   won't load. `install_cleanStalePathdef` strips obviously stale
   entries; new restructures may need additions.

---

## Quick pointers

- `install.m:1` — installer entry point (heavy comments throughout).
- `src/ndi/+ndi/+nansen/startup.m:1` — runtime entry; the cloud + GUI flow.
- `src/ndi/+ndi/+nansen/+sync/repo.m:1` — canonical Pattern B example.
- `src/ndi/+ndi/+nansen/+fun/runTagged.m:1` — output grouping helper.
- `src/pulakat/code/+pulakat/module.nansen.json` — NANSEN module manifest.
- `src/ndi/+ndi/+setup/+conv/+pulakat/project_info.json` — cloud dataset ID and project paths.
- `.github/workflows/matlab-tests.yml` — full CI recipe (offline + cloud tiers).
