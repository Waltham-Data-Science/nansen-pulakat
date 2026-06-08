# User Guide

How to launch the app and do the two things you'll do most often. If you
haven't installed yet, start with [Getting Started](getting-started.md). For a
full list of what every menu action does, see the [Reference](reference.md).

- [Launching the App](#launching-the-app)
- [Searching for Records](#searching-for-records)
- [Adding New Records](#adding-new-records)

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

### If startup is hanging

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

For a full list of every method on each table, see the
**[Reference](reference.md)**.
