# nansen-pulakat: Data Management System

This repository provides a database system that enables the organization and cloud syncing of experimental sessions, subjects, and files. It provides a graphical user interface (GUI) for managing research data and ensuring it is securely backed up and accessible.

## Getting Started

### First Time Setup
1.  **Git Installation:** Make sure `git` is installed.
    - **Windows:** Download from [git-scm.com](https://git-scm.com/download/win).
    - **Mac:** Open terminal and run `xcode-select --install`.
    - **Linux:** Use your distribution's package manager.
2.  **Download Installer:** Download [install.m](https://github.com/Waltham-Data-Science/nansen-pulakat/raw/main/install.m).
3.  **Run in MATLAB:** Execute `install.m` in the MATLAB Command Window.

### Subsequent Uses
Run `pulakat.startup` to initialize the environment, sync with the NDI cloud, and open the GUI.

---

## Workflow Overview

1.  **Import Session:** Add a new experimental session (day/recording) to the Dataset table.
2.  **Import Subjects:** Use **Import > Subjects > Files** (detects from `animal_mapping.csv`) or **Manual** to add animals to a session.
3.  **Import Files:** Use **Import > Files > Auto** or **Manual** to link data files (.svs, .bimg, etc.) to subjects.
4.  **Validate & Edit:** Verify metadata and correct errors *before* committing to NDI.
5.  **Commit/Sync:** Use the **Sync** method on the Dataset table to create NDI documents and upload to the cloud.

---

## Table Methods

The following methods are accessible through the "Methods" menu when a record is selected in the corresponding table.

### Dataset Table

| Method | Description |
| :--- | :--- |
| **Import > Session** | Select a session directory and give it a unique name. |
| **Sync** | Creates NDI documents and performs a two-way sync with the cloud. |

### Session Table

| Method | Description |
| :--- | :--- |
| **Import > Subjects > Files** | Detects and imports subjects from lab-standard metadata files. |
| **Import > Subjects > Manual** | Opens a dialog to manually enter subject details (ID, Cage, Label, etc.). |
| **Import > Files > Auto** | Scans the session directory for files matching supported data types. |
| **Import > Files > Manual** | Allows manual selection of files and assignment of data types and subjects. |
| **Export > Metadata** | Exports session metadata to a file. |
| **Export > Files** | Exports session files. |
| **Remove** | Removes the selected session from the local metatable (only if not yet synced). |

### Subject Table

| Method | Description |
| :--- | :--- |
| **Validate** | Performs a "dry run" validation of subject metadata. |
| **Edit** | Allows editing of subject metadata (locked once synced). |
| **Export > Metadata** | Exports subject metadata to a file. |
| **Export > Files** | Exports subject files. |
| **Remove** | Deletes the subject record from the local metatable. |

### File Table

| Method | Description |
| :--- | :--- |
| **Validate** | Checks for physical file existence and valid data type assignments. |
| **Export** | Exports selected files. |
| **Remove** | Removes the file record from the metatable. |

---

## Identification & Synchronization

### UUID Tethers
Every record (Subject, File) is assigned an immutable `UUID` (e.g., `Subject-xxxx...`). This identifier tethers the record to the corresponding NDI document, ensuring links survive metadata renames.

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
