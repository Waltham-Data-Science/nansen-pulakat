# CLAUDE.md

Reference for Claude Code sessions working on **nansen-pulakat**. It
summarises three coupled repos and the conventions in this codebase
so a session can pick up cold.

---

## What this repo is

`nansen-pulakat` is a MATLAB data-management application for the Pulakat
lab. It stitches together two upstream frameworks and adds the
lab-specific glue and GUI extensions.

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
| NANSEN (GUI framework)   | App shell, metadata tables, plugin loader                  | `VervaekeLab/NANSEN`, `dev` branch                |
| NDI-matlab (DB/cloud)    | Dataset model, document store, NDI cloud sync              | `VH-Lab/NDI-matlab`                               |
| openMINDS_MATLAB         | Ontology types used by NDI                                 | `openMetadataInitiative/openMINDS_MATLAB`         |
| entity-table             | R2025a+ MetaTableViewer backend (NANSEN PR #77)            | `ehennestad/entity-table`                         |

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

For NANSEN abstract classes, NDI cloud calls, and plugin-discovery
behaviour, those checkouts are the source of truth.

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
└── tests/+ndi/+unittest/+nansen/      # Test classes (offline + cloud)
```

Two structural facts:

- **`+pulakat/+tablevariable/...` and `+pulakat/+{object,session}method/...`
  are discovered by NANSEN by folder/name convention.** No central
  registry — the directory layout *is* the manifest.
- **The integration layer reuses the `ndi.*` namespace**
  (`src/ndi/+ndi/+nansen/...`). It sits next to upstream NDI-matlab
  on the path; both populate `ndi`.

---

## Runtime flow

### Fresh install (client machine)
`install.m` is the only thing the user runs. It:

1. Checks for `git` on PATH.
2. Bootstraps `ndi.nansen.sync.repo` via `websave` if not yet on path.
3. Clones (in order) nansen-pulakat → NANSEN (`dev`) → entity-table → openMINDS → NDI-matlab into
   `~/ndi/tools/` (overridable via the `codePath` arg). entity-table
   is required by NANSEN's MATLAB R2025a+ MetaTableViewer (NANSEN PR
   #77); the sibling clone is one of the candidate paths probed by
   `nansen.util.ensureEntityTableOnPath`.
4. Runs each upstream installer (`nansen_install`, openMINDS `setup.m`,
   `ndi_install`) inside `install_runTagged` so their output is grouped
   under `[Nansen Install]` / `[openMINDS Setup]` / `[NDI Install]`.
5. Strips stale pre-restructure pathdef entries (old `pulakat/code`,
   `pulakat/code-NDI`, etc.) before NDI's path-reset re-applies them.
6. `addpath(install_genpathClean(codePath))` (filter is duplicated in
   the runtime `ndi.nansen.fun.cleanGenpath` helper).
7. Re-applies the captured **install-entry path snapshot** (PR #45) so
   any MATLAB-default directories that `nansen_install` / `ndi_install`
   dropped during the install (R2026a `appdesigner/runtime`,
   especially) are restored before `savepath`.
8. `savepath` to **`userpath/pathdef.m`** (matlabroot is often read-only).
9. Appends an idempotent pathdef-loader to `userpath/startup.m` so future
   MATLAB launches restore the saved path.
10. Calls `ndi.nansen.startup('pulakat', dataPath, 'SkipRepoSync', true)`.

### Subsequent launches
- A plain MATLAB restart auto-loads paths via the `userpath/startup.m`
  snippet — code is available but no cloud sync happens.
- `pulakat.startup` (or `ndi.nansen.startup('pulakat')`) syncs with NDI
  cloud and opens the GUI.
- Both support `Headless=true` for CI/scripting.

---

## Cross-repo coupling

Upstream surfaces this codebase consumes:

| We use                                              | Upstream defines                                |
|-----------------------------------------------------|-------------------------------------------------|
| `nansen.metadata.abstract.TableVariable`            | NANSEN — every `+pulakat/+tablevariable/*` subclasses it |
| NANSEN's plugin loader / module manifest            | NANSEN — `module.nansen.json` schema            |
| `nansen.ProjectManager`                             | NANSEN — used in `ndi.nansen.startup`           |
| `nansen` (the GUI launcher function)                | NANSEN                                          |
| `ndi.dataset.dir`                                   | NDI-matlab — top-level dataset object           |
| `ndi.cloud.{testLogin,uilogin,downloadDataset,sync.downloadNew,authenticate}` | NDI-matlab |
| `ndi_install`, `nansen_install`                     | both — invoked by `install.m`                   |
| `nansen.util.ensureEntityTableOnPath`               | NANSEN — gates the modern table backend on R2025a+ |

NANSEN is pinned to its `dev` branch; CI checks out `dev` for every run.

### MATLAB version coupling

NANSEN PR #77 split `MetaTableViewer` into a legacy Java backend
(pre-R2025a) and a modern uifigure/EntityTable backend (R2025a+). The
release decision lives in `nansen.util.useModernUiTable`. Pulakat's
`+tablevariable/*` classes only override `getCellDisplayString` with
plain text and inherit the abstract default for
`getCellDisplayStringForContext`, so they render correctly under both
backends without any per-context branches. If a future pulakat
formatter ever needs HTML / icon rendering, override
`getCellDisplayStringForContext(obj, displayContext)` instead of
`getCellDisplayString` and emit emoji/plain text when
`displayContext == "modern"`.

---

## Conventions

### Tagged output ("Pattern B")

All status/warning/error output in the integration layer carries a
bracket prefix so a user can paste a single line and a developer can
grep straight to source.

- **Info lines** use a short module tag:
  `fprintf('[%s] message\n', infoTag)` where `infoTag` is e.g.
  `'NDI Startup'`, `'Pulakat'`, `'Install'`.
- **Warnings and errors** use a full MException-style ID and embed
  that exact ID as a bracket prefix in the message:

  ```matlab
  warning([funcId, ':CloneFailed'], ...
      '[%s:CloneFailed] Clone failed: %s', funcId, cmdOut);
  ```

  The printed prefix matches the throw identifier exactly:
  `[NDI:Nansen:Sync:Repo:CloneFailed]`, not just
  `[NDI:Nansen:Sync:Repo]`.

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
See `ndi.nansen.startup` and `install.m` for the tone.

### MException ID namespace

- Integration layer: `NDI:Nansen:<Subsystem>:<Reason>`
  (e.g. `NDI:Nansen:Sync:Repo:CloneFailed`, `NDI:Nansen:Startup:NotAuthenticated`).
- Installer: `Install:<Reason>` (e.g. `Install:GitNotFound`).
- Pulakat layer: `Pulakat:<Subsystem>:<Reason>`.

---

## Tests

Layout: `tests/+ndi/+unittest/+nansen/<TestClassName>.m`

Two CI tiers in `.github/workflows/matlab-tests.yml`:

- **Offline tests** (every push/PR): project setup, metatable ops,
  file parsing, importers, sync, plus the discovery-driven plugin
  classes below. Run by listing class names in the workflow file.
- **Cloud tests** (gated on `NDI_CLOUD_USERNAME`/`NDI_CLOUD_PASSWORD`
  secrets): `CreateDataset`, `Startup`, `ImportSession`. Skipped with
  a notice when secrets aren't configured (e.g. on PRs from forks).
  Cloud env defaults to `prod`; override with `CLOUD_API_ENVIRONMENT`.

CI pre-clones DID-matlab, vhlab-toolbox-matlab, mksqlite (building the
MEX with `buildit.m`), openMINDS_MATLAB (for ontology types NDI uses),
and entity-table (for NANSEN's R2025a+ MetaTableViewer backend), because
NDI's database backend dispatches through `did.implementations.sqlitedb`
and NANSEN dev expects entity-table on the path.

After matbox is installed via `ehennestad/matbox-actions/install-matbox`,
CI runs `nansen.config.addons.AddonManager.instance(...).installMissingAddons()`
against NANSEN's `requirements.txt` so the FEX-managed dependencies
(recursiveDir, widgets-toolbox, etc.) are available; without this the
metatable tests crash on `recursiveDir` (PR #47).

Local run (rough): `addpath(genpath('src')); addpath(genpath('tests')); runtests('tests/+ndi/+unittest/+nansen')`
after the upstream repos are on the path.

Three discovery-driven test classes scale across modules without
per-lab edits:

- `ndi.unittest.nansen.ModulePlugins` — walks every `+<name>` package
  with a `module.nansen.json` manifest and emits one parameterised
  case per tablevariable / objectmethod / sessionmethod file: class
  loads, no-arg constructor succeeds, inheritance includes
  `nansen.metadata.abstract.TableVariable`, no-arg method call
  returns a struct.
- `ndi.unittest.nansen.ModuleManifest` — for every discovered module,
  validates `module.nansen.json` (Properties.Name matches the
  `+<name>` folder, Description present) and the paired
  `+ndi/+setup/+conv/+<name>/project_info.json` (parses, has every
  field the integration layer consumes, `name` matches the module,
  `projectRelativePath` resolves to a real folder).
- `ndi.unittest.nansen.JsonConfigs` — walks `src/` and asserts every
  `*.json` parses with `jsondecode` and is non-empty.

`ModulePlugins.discoverModules` and `ModulePlugins.repoRoot` are the
shared static helpers the other two classes call.

---

## Branching and commits

- Working branches use `claude/<short-task-name>-<random-suffix>`.
- Commit messages: short imperative subject, no trailing period.
  Body explains the *why* for non-trivial changes. See
  `git log --oneline` for tone.
- Subjects use single-quoted MATLAB function names where helpful
  (e.g. "Apply pattern B to src/pulakat and align tests").

---

## Quick pointers

- `install.m:1` — installer entry point (heavy comments throughout).
- `src/ndi/+ndi/+nansen/startup.m:1` — runtime entry; the cloud + GUI flow.
- `src/ndi/+ndi/+nansen/+sync/repo.m:1` — canonical Pattern B example.
- `src/ndi/+ndi/+nansen/+fun/runTagged.m:1` — output grouping helper.
- `src/pulakat/code/+pulakat/module.nansen.json` — NANSEN module manifest.
- `src/ndi/+ndi/+setup/+conv/+pulakat/project_info.json` — cloud dataset ID and project paths.
- `.github/workflows/matlab-tests.yml` — full CI recipe (offline + cloud tiers).
