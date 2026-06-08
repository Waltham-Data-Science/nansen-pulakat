# User Guide

How to launch the app, do the two things you'll do most often, and look up
what every menu action does. If you haven't installed yet, start with
[Getting Started](getting-started.md).

- [Launching the App](#launching-the-app)
- [Searching for Records](#searching-for-records)
- [Adding New Records](#adding-new-records)
- [Reference: Table Methods](#reference-table-methods)

---

## Launching the App

The installer adds a pathdef loader to `<userpath>/startup.m`, so the NDI,
NANSEN, and pulakat packages are on the MATLAB path automatically every
time MATLAB starts. To **sync with the NDI cloud and open the Nansen GUI**,
run:

```matlab
pulakat.startup
```

A plain MATLAB restart makes the code available but won't pull any cloud
updates — `pulakat.startup` is what performs the sync.

![The Nansen GUI on first launch, showing the Dataset table](images/gui-overview.png)

### Launch options

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

The **Sync** method on the Dataset table still runs a full cloud round-trip
when you click it explicitly.

---

## Searching for Records

Use this when you want to **find** existing sessions, subjects, or files —
for example, to check whether an animal has already been imported, or to
locate every file linked to one session.

1.  **Pick the right table.** Switch between the **Dataset**, **Session**,
    **Subject**, and **File** tables using the table selector. Each row is
    one record.

    ![The table selector for switching between Dataset, Session, Subject, and File](images/table-selector.png)

2.  **Sort by a column.** Click a column header to sort ascending; click
    again for descending. Useful for grouping records by subject, date, or
    data type.

3.  **Filter to narrow the list.** Open the column filter to show only rows
    matching a value (e.g. a subject ID or a file type). Combine filters
    across columns to drill down.

    ![Filtering the Subject table by an identifier](images/filter-records.png)

4.  **Read the metadata.** Select a row to inspect its full metadata, and
    follow the links between tables (a session lists its subjects; a subject
    lists its files) to trace a record through the dataset.

> **Tip:** To pull down the latest records added by collaborators before
> searching, run a **Sync** (or relaunch with `pulakat.startup`) so your
> local tables reflect the current cloud state.

---

## Adding New Records

The normal path for getting new experimental data into the dataset and up to
the cloud. Work through the steps in order — each one builds on the last.

1.  **Import a session.** On the **Dataset** table, choose
    **Import > Session**, select the session directory, and give it a
    unique session name. This adds a new experimental session (a day /
    recording) to the dataset.

    ![Importing a new session from the Dataset table](images/import-session.png)

2.  **Import subjects.** On the **Session** table, use
    **Import > Subjects > Files** to detect animals automatically from
    `animal_mapping.csv`, or **Import > Subjects > Manual** to enter
    subject identifiers by hand.

    ![Importing subjects into a session](images/import-subjects.png)

3.  **Import data files.** Still on the **Session** table, use
    **Import > Data > Folder** to scan the session directory for supported
    data types, or **Import > Data > Files** to pick specific files and
    assign their data types and subjects.

4.  **Validate and edit.** Before committing anything to NDI, run **Validate**
    on the Subject and File tables to catch problems (missing files, bad data
    types, broken subject links), and use **Edit** to correct metadata.
    Records become locked once they're synced, so fix them now.

    ![Validating subject metadata before syncing](images/validate-records.png)

5.  **Commit and sync.** On the **Dataset** table, run **Sync**. This creates
    the official NDI documents, establishes immutable UIDs, and uploads
    everything to the cloud.

> **Heads up:** **Import** actions on the Session table accept a single
> session at a time. Most other table methods support selecting multiple
> records for batch processing.

---

## Reference: Table Methods

The following methods are accessible through the "Methods" menu when a record
is selected in the corresponding table.

**Note on Selection:** Most table methods allow selecting multiple records for
batch processing. However, methods under **Import** (specifically Session
Methods) typically accept only a single session input at a time.

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
