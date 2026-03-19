# nansen-pulakat: Nansen-NDI Integration

This repository provides an integration between the **Nansen** data management framework and the **Neuroscience Data Interface (NDI)**. It is specifically configured for the **Pulakat Lab**, but the core logic is designed to be extensible.

## Getting Started

### First Time Setup
1.  **Git Installation:** Make sure `git` is installed.
    - **Windows:** Download from [git-scm.com](https://git-scm.com/download/win).
    - **Mac:** Open terminal and run `xcode-select --install`.
    - **Linux:** Use your distribution's package manager.
2.  **Download Installer:** Download [install.m](https://github.com/Waltham-Data-Science/nansen-pulakat/raw/main/install.m).
3.  **Run in MATLAB:** Execute `install.m` in the MATLAB Command Window.

### Subsequent Uses
Run `pulakat.startup` to initialize the environment, sync with the NDI cloud, and open the Nansen GUI.

---

## Workflow Overview

1.  **Import Session:** Add a new experimental session (day/recording) to the Nansen Dataset table.
2.  **Import Subjects:** Use **Import > Subjects > Auto** (detects from `animal_mapping.csv`) or **Manual** to add animals to a session.
3.  **Import Files:** Use **Import > Files > Auto** or **Manual** to link data files (.svs, .bimg, etc.) to subjects.
4.  **Validate & Edit:** Verify metadata and correct errors *before* committing to NDI.
5.  **Commit/Sync:** Use the **Sync** method on the Dataset table to create NDI documents and upload to the cloud.
6.  **Undo (Recovery):** If errors are found after commitment but before cloud sync, use the **Undo** method on the Dataset table to revert local NDI documents.

---

## Nansen GUI Methods

Methods are divided into "Session Methods" (Dataset table) and "Object Methods" (Subject/File tables).

### Session Methods (Dataset Table)

| Method | Description |
| :--- | :--- |
| **Import > Session** | Select a session directory and give it a unique name. |
| **Import > Subjects > Auto** | Detects and imports subjects from lab-standard metadata files. |
| **Import > Subjects > Manual** | Enter subject details (ID, Cage, Label, Strain) manually. |
| **Sync** | Creates NDI documents and performs a two-way sync with the cloud. |
| **Undo** | Reverts local NDI document creations that haven't been synced yet. |

### Object Methods (Subject Table)

| Method | Description |
| :--- | :--- |
| **Validate** | Dry-run validation of metadata against NDI/openMINDS ontologies. |
| **Edit** | Edit animal metadata (locked once synced to NDI). |
| **Remove** | Delete the subject record from the local metatable. |

### Object Methods (File Table)

| Method | Description |
| :--- | :--- |
| **Import > Files > Auto** | Scans session directory for supported data types. |
| **Import > Files > Manual** | Manually pick files and assign data types/subjects. |
| **Validate** | Checks physical file existence and data type validity. |

---

## Identification & Synchronization

### UUID Tethers
Every record (Subject, File) is assigned an immutable `Nansen_UUID` (e.g., `Subject-xxxx...`). This identifier tethers the Nansen record to the corresponding NDI document, ensuring links survive metadata renames.

### The Commitment Phase
The **Sync** process implements a 4-Tier Hierarchical Ownership model:
- **Dataset -> Session -> Subject -> Files**
NDI documents are created with strict referential integrity (children depend on parent UIDs).

---

## Documentation for Developers

Standard MATLAB help blocks are available for all core integration functions.
```matlab
help ndi.nansen.import.subject
help ndi.nansen.fun.getIdentifier
help ndi.nansen.sync.undo
```
