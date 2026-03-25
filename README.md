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

**Note on Selection:** Most table methods allow selecting multiple records for batch processing. However, methods under **Import** (specifically Session Methods) typically accept only a single session input at a time.

### Dataset Table (Object Methods)

| Method | Description |
| :--- | :--- |
| **Import > Session** | Select a session directory and provide a unique session name to add it to the dataset. |
| **Sync** | Performs a two-way synchronization with the NDI cloud, uploading new documents and downloading remote updates. |

### Session Table (Session Methods)

| Method | Description |
| :--- | :--- |
| **Import > Subjects > Files** | Automatically detects and imports subjects from lab-standard metadata files (e.g., `animal_mapping.csv`). |
| **Import > Subjects > Manual** | Opens a dialog to manually enter subject details (ID, Cage, Label, etc.) for the selected session. |
| **Import > Data > Folder** | Scans the session directory for files matching supported data types and imports them. |
| **Import > Data > Files** | Allows manual selection of specific files and assignment of data types and subjects. |
| **Export > Metadata** | Exports consolidated metadata for the selected session to a CSV file. |
| **Export > Files** | Exports all data files associated with the selected session. |
| **Remove** | Removes the selected session from the local metatable and unlinks it from the NDI dataset. |

### Subject Table (Object Methods)

| Method | Description |
| :--- | :--- |
| **Validate** | Performs a "dry run" validation of subject metadata against project requirements and ontology rules. |
| **Edit** | Opens a GUI to edit subject metadata (locked once the record is synced to the cloud). |
| **Document** | Creates the official NDI subject documents and establishes immutable UIDs in the database. |
| **Merge Duplicates** | Identifies and merges duplicate subject records based on shared identification metadata. |
| **Export > Metadata** | Exports metadata for the selected subjects to a CSV file. |
| **Export > Files** | Exports all data files associated with the selected subjects. |
| **Remove** | Deletes the subject record and its associated data files from the local metatable. |

### File Table (Object Methods)

| Method | Description |
| :--- | :--- |
| **Validate** | Checks for physical file existence, valid data type assignments, and proper subject links. |
| **Document** | Creates the official NDI file documents and establishes immutable UIDs in the database. |
| **Export** | Exports selected data files and their associated metadata. |
| **Remove** | Removes the file record from the metatable (only if not yet synced to the cloud). |

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
