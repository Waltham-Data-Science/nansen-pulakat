# Nansen-NDI Integration: Pulakat Lab

This repository provides an integration between the **Nansen** data management framework and the **Neuroscience Data Interface (NDI)**. It is specifically configured for the **Pulakat Lab**, but the core logic is designed to be extensible.

## Table of Contents
1. [Overview](#overview)
2. [Workflow](#workflow)
3. [Nansen Methods](#nansen-methods)
    - [Session Methods](#session-methods)
    - [Object Methods (Subject)](#object-methods-subject)
    - [Object Methods (File)](#object-methods-file)
4. [Identification & Synchronization](#identification--synchronization)
5. [Documentation for Developers](#documentation-for-developers)

---

## Overview

The integration allows researchers to manage experimental metadata (sessions, subjects, and files) within the Nansen GUI while ensuring that all data is eventually synchronized and tethered to unique NDI documents in the cloud.

## Workflow

1.  **Startup:** Run `pulakat.startup` to initialize the environment, sync with the cloud, and open the Nansen GUI.
2.  **Import Session:** Add a new experimental session to the Nansen Dataset table.
3.  **Import Subjects:** Use **Import > Subjects > Auto** (from metadata files like `animal_mapping.csv`) or **Manual** to add subjects to a session.
4.  **Import Files:** Use **Import > Files > Auto** or **Manual** to associate experimental data files with subjects.
5.  **Validate & Edit:** Check metadata for errors and edit if necessary *before* syncing to NDI.
6.  **Commit/Sync:** Use the **Sync** method on the Dataset table to create NDI documents and upload data to the cloud.

---

## Nansen Methods

Methods are accessible through the Nansen GUI menus. They are divided into "Session Methods" (acting on sessions) and "Object Methods" (acting on specific subjects or files).

### Session Methods

These methods are found in the **Methods** menu when a Session is selected in the Dataset table.

| Method | Description |
| :--- | :--- |
| **Import > Subjects > Auto** | Automatically detects and imports subjects from lab-standard metadata files in the session directory. |
| **Import > Subjects > Manual** | Opens a dialog to manually enter subject details (ID, Cage, Label, Strain, etc.). |
| **Import > Subjects > Files** | Imports subjects by selecting specific metadata files. |
| **Remove** | Removes the selected session from the local Nansen metatable (only if not yet synced). |

### Object Methods (Subject)

These methods are found in the **Methods** menu when viewing the Subject table for a session.

| Method | Description |
| :--- | :--- |
| **Validate** | Performs a "dry run" validation of subject metadata against NDI requirements and lab-specific ontologies (e.g., valid strain names). |
| **Edit** | Allows editing of subject metadata (ID, Cage, Label, etc.) in a GUI. **Note:** Locked once a subject is synced to NDI. |
| **Remove** | Deletes the subject record from the local metatable. |
| **Export > Metadata** | Exports the current subject metadata to a CSV/XLSX file. |

### Object Methods (File)

These methods are found in the **Methods** menu when viewing the File table for a subject.

| Method | Description |
| :--- | :--- |
| **Import > Files > Auto** | Automatically scans the session directory for files matching supported lab data types (e.g., .svs, .bimg). |
| **Import > Files > Manual** | Allows manual selection of files and assignment of data types and subjects. |
| **Validate** | Checks for physical file existence and valid NDI data type assignments. |
| **Edit** | Edits file metadata (Data Type, Filename). Locked after sync. |
| **Remove** | Removes the file record from the metatable. |

---

## Identification & Synchronization

### UUID Tethers
Every record (Subject, File) is assigned a unique, immutable `Nansen_UUID` (e.g., `Subject-xxxx...`) using `java.util.UUID`. This identifier tethers the Nansen record to the corresponding NDI document, even if metadata like subject names or filenames change.

### The "Sync" Process
The **Sync** method (on the Dataset table) performs the following:
1.  **Validation:** Runs all validation checks.
2.  **Commitment:** Creates NDI documents for new subjects and files.
3.  **Cloud Sync:** Uploads the new documents and associated files to the NDI cloud.
4.  **Status Update:** Updates the local Nansen metatables with `DocumentIdentifier` and `Cloud` status.

---

## Documentation for Developers

All functions in the `+ndi` package include standard MATLAB help blocks. You can access them using the `help` command in the MATLAB Command Window, for example:
```matlab
help ndi.nansen.import.subject
help ndi.nansen.fun.getIdentifier
```
