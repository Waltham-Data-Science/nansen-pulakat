# Reference

The lists below mirror the **Methods** menu for each table — the indentation
matches the dropdown you click through when an entry is selected. For task
walkthroughs that use these methods, see the [User Guide](user-guide.md).

**Note on Selection:** Most table methods allow selecting multiple entries for
batch processing. However, methods under **Import** (specifically Session
Methods) typically accept only a single session input at a time.

## Dataset Table

- **Import**
  - **Session** — Select a session directory and provide a unique session name to add it to the dataset.
- **Sync** — Performs a two-way synchronization with the NDI cloud, downloading remote updates and uploading new documents.

## Session Table

- **Import**
  - **Subjects**
    - **Files** — Automatically detects and imports subjects from lab-standard metadata files (e.g., `animal_mapping.csv`).
    - **Manual** — Opens a dialog to manually enter subject identifiers (the fields are configured per project in `+ndi/+setup/+conv/<lab>/project_info.json`).
  - **Data**
    - **Folder** — Scans the session directory for files matching supported data types and imports them.
    - **Files** — Allows manual selection of specific files and assignment of data types and subjects.
- **Export**
  - **Metadata** — Exports consolidated metadata for the selected session to a CSV file.
  - **Files** — Exports all data files associated with the selected session.
- **Remove** — Removes the selected session from the local metatable and unlinks it from the NDI dataset.

## Subject Table

- **Validate** — Performs a "dry run" validation of subject metadata against project requirements and ontology rules.
- **Edit** — Opens a GUI to edit subject metadata (locked once the entry is synced to the cloud).
- **Document** — Creates the official NDI subject documents and establishes immutable UIDs in the database.
- **Merge Duplicates** — Identifies and merges duplicate subject entries based on shared identification metadata.
- **Export**
  - **Metadata** — Exports metadata for the selected subjects to a CSV file.
  - **Files** — Exports all data files associated with the selected subjects.
- **Remove** — Deletes the subject entry and its associated data files from the local metatable.

## File Table

- **Validate** — Checks for physical file existence, valid data type assignments, and proper subject links.
- **Document** — Creates the official NDI file documents and establishes immutable UIDs in the database.
- **Export** — Exports selected data files and their associated metadata.
- **Remove** — Removes the file entry from the metatable (only if not yet synced to the cloud).
