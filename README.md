# nansen-pulakat: Data Management System

[![MATLAB Tests](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml)
[![codecov](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat/branch/main/graph/badge.svg)](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat)

This repository provides a database system that enables the organization and cloud syncing of experimental sessions, subjects, and files. It provides a graphical user interface (GUI) for managing research data and ensuring it is securely backed up and accessible.

## Getting Started

### Requirements

- **MATLAB R2023a or newer.** R2025a and R2026a get a modernised
  metatable backend (web-based uitable, drag-to-resize columns) via
  the `entity-table` dependency that `install.m` clones for you;
  pre-R2025a uses the legacy Java backend automatically.
- **An NDI cloud account.** The installer's last step prompts you to
  sign in via `ndi.cloud.uilogin`. If you don't have one yet, request
  one from the [NDI cloud admin](https://ndi-cloud.com) before running
  `install.m` — the installer can still finish without an account, but
  the dataset sync step will be skipped.
- **Disk space** for the dataset cache. The cloud dataset downloads
  into `~/ndi/data/<cloudDatasetID>/` on first launch and grows with
  the dataset. Plan for a few times the size of the cloud dataset
  (the binaries plus a SQLite index) — a 50 GB cloud dataset
  comfortably fits in 100 GB local.

### First Time Setup

1.  **Install Git** if you don't already have it.
    - **Windows:** Download from [git-scm.com](https://git-scm.com/download/win).
    - **Mac:** Open Terminal and run `xcode-select --install`.
    - **Linux:** Use your distribution's package manager.

2.  **Download and run `install.m`.** There are two equivalent ways — pick whichever is more convenient. The installer will clone the dependencies, set up your MATLAB paths, sync with the NDI cloud, and open the Nansen GUI.

    **Option A — From MATLAB (recommended).** Open MATLAB and paste this snippet into the Command Window:

    ```matlab
    cd(tempdir)
    url = 'https://raw.githubusercontent.com/Waltham-Data-Science/nansen-pulakat/main/install.m';
    websave('install.m', url);
    install
    ```

    This downloads `install.m` to MATLAB's temp folder and runs it — no browser steps required.

    **Option B — From your browser.** Visit the [install.m page on GitHub](https://github.com/Waltham-Data-Science/nansen-pulakat/blob/main/install.m), click the **Download raw file** button on the right side of the file's toolbar, then in MATLAB:

    ```matlab
    cd('~/Downloads')   % or wherever the file was saved
    install
    ```

3.  **Sign in to NDI cloud** when prompted. The installer ends with
    an `ndi.cloud.uilogin` dialog; enter the email and password for
    your NDI cloud account. The credentials persist for subsequent
    MATLAB sessions until you log out.

#### If the install fails partway

`install.m` is **idempotent** — re-running it picks up where the
previous attempt left off. The most common partial-install signals
and what to do:

- **Network errors during a `git clone`.** Re-run `install`. Already-
  cloned repos are detected and pulled instead of re-cloned.
- **`Could not save MATLAB path to ...`.** Your `userpath` is read-
  only. Find a writable folder, set `userpath` to it
  (`userpath('/some/writable/path')`), then re-run `install`.
- **`matlab.apps.AppBase ... cannot be found on MATLAB's search
  path`** on R2026a. The installer's path-restore step
  (PR #45) should have prevented this; if it still appears, run
  `restoredefaultpath; rehash` then re-run `install`.

If none of those apply, delete `~/ndi/tools/` and `<userpath>/pathdef.m`
and start over.

### Subsequent Uses

The installer adds a pathdef loader to `<userpath>/startup.m`, so the NDI,
NANSEN, and pulakat packages are on the MATLAB path automatically every
time MATLAB starts. Running `pulakat.startup` is what you use to **sync
with the NDI cloud and open the Nansen GUI** — a plain MATLAB restart
will have the code available but won't pull any cloud updates.

For scripted / CI contexts where the GUI must not open, pass `Headless`:

```matlab
pulakat.startup('Headless', true)
```

Headless mode requires you to already be authenticated with NDI cloud
(e.g. via a prior interactive `ndi.cloud.uilogin` run).

If the cloud sync step at startup is hanging (a stuck upload, network
partition), skip it and open the GUI against the local cache:

```matlab
pulakat.startup('SkipCloudSync', true)
```

The Sync table-method action on the Dataset table still runs a full
cloud round-trip when you click it explicitly.

### Updating to the latest version

Re-run `install.m`. The installer detects the existing checkouts and
runs `git pull` on each instead of re-cloning. No need to wipe state
or re-authenticate.

---

## Workflow Overview

1.  **Import Session:** Add a new experimental session (day/recording) to the Dataset table.
2.  **Import Subjects:** Use **Import > Subjects > Files** (detects from `animal_mapping.csv`) or **Manual** to add animals to a session.
3.  **Import Data Files:** Use **Import > Data > Folder** or **Files** to link data files (.svs, .bimg, etc.) to subjects.
4.  **Validate & Edit:** Verify metadata and correct errors *before* committing to NDI.
5.  **Commit/Sync:** Use the **Sync** method on the Dataset table to create NDI documents and upload to the cloud.

---

## Table Methods

The following methods are accessible through the "Methods" menu when a record is selected in the corresponding table.

**Note on Selection:** Most table methods allow selecting multiple records for batch processing. However, methods under **Import** (specifically Session Methods) typically accept only a single session input at a time.

### Dataset Table

| Method | Description |
| :--- | :--- |
| **Import > Session** | Select a session directory and provide a unique session name to add it to the dataset. |
| **Sync** | Performs a two-way synchronization with the NDI cloud, downloading remote updates and uploading new documents. |

### Session Table

| Method | Description |
| :--- | :--- |
| **Import > Subjects > Files** | Automatically detects and imports subjects from lab-standard metadata files (e.g., `animal_mapping.csv`). |
| **Import > Subjects > Manual** | Opens a dialog to manually enter subject identifiers (the fields are configured per project in `+ndi/+setup/+conv/<lab>/project_info.json`). |
| **Import > Data > Folder** | Scans the session directory for files matching supported data types and imports them. |
| **Import > Data > Files** | Allows manual selection of specific files and assignment of data types and subjects. |
| **Export > Metadata** | Exports consolidated metadata for the selected session to a CSV file. |
| **Export > Files** | Exports all data files associated with the selected session. |
| **Remove** | Removes the selected session from the local metatable and unlinks it from the NDI dataset. |

### Subject Table

| Method | Description |
| :--- | :--- |
| **Validate** | Performs a "dry run" validation of subject metadata against project requirements and ontology rules. |
| **Edit** | Opens a GUI to edit subject metadata (locked once the record is synced to the cloud). |
| **Document** | Creates the official NDI subject documents and establishes immutable UIDs in the database. |
| **Merge Duplicates** | Identifies and merges duplicate subject records based on shared identification metadata. |
| **Export > Metadata** | Exports metadata for the selected subjects to a CSV file. |
| **Export > Files** | Exports all data files associated with the selected subjects. |
| **Remove** | Deletes the subject record and its associated data files from the local metatable. |

### File Table

| Method | Description |
| :--- | :--- |
| **Validate** | Checks for physical file existence, valid data type assignments, and proper subject links. |
| **Document** | Creates the official NDI file documents and establishes immutable UIDs in the database. |
| **Export** | Exports selected data files and their associated metadata. |
| **Remove** | Removes the file record from the metatable (only if not yet synced to the cloud). |

---

## Documentation for Developers

Standard MATLAB help blocks are available for all core integration functions.
```matlab
help ndi.nansen.import.subject
help ndi.nansen.fun.getIdentifier
help ndi.nansen.sync.status
help ndi.nansen.sync.repo
help ndi.nansen.startup
```
