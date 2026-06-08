# User Guide

How to launch the app and work with your data day to day. If you haven't
installed yet, start with [Getting Started](getting-started.md). For a full
list of what every menu action does, see the [Reference](reference.md).

- [Launching the App](#launching-the-app)
- [Understanding the Tables](#understanding-the-tables)
- [Searching for Entries](#searching-for-entries)
- [Adding New Entries](#adding-new-entries)
- [Editing Metadata](#editing-metadata)
- [Exporting Data](#exporting-data)
- [Removing Entries](#removing-entries)
- [Syncing with the Cloud](#syncing-with-the-cloud)
- [Getting Help](#getting-help)

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

## Understanding the Tables

Your data is organised into four tables, each one a level of detail below the
last:

| Table | What one entry is |
| :--- | :--- |
| **Dataset** | The whole collection — the thing that syncs to the cloud. |
| **Session** | A single experimental session (a day / recording). |
| **Subject** | An animal within a session. |
| **File** | A data file (`.svs`, `.bimg`, …) linked to a subject. |

The tables are nested: a dataset holds sessions, a session holds subjects, and
a subject holds files. You switch between them with the table selector, and you
can follow the links between them — a session lists its subjects, a subject
lists its files — to trace any entry up or down the hierarchy.

![The table selector for switching between Dataset, Session, Subject, and File](images/table-selector.png)

---

## Searching for Entries

Use this when you want to **find** existing sessions, subjects, or files —
for example, to check whether an animal has already been imported, or to
locate every file linked to one session.

1.  **Pick the right table** with the table selector. Each row is one entry.

2.  **Sort by a column.** Click a column header to sort ascending; click
    again for descending. Useful for grouping entries by subject, date, or
    data type.

3.  **Filter to narrow the list.** Open the column filter to show only rows
    matching a value (e.g. a subject ID or a file type). Combine filters
    across columns to drill down.

    ![Filtering the Subject table by an identifier](images/filter-entries.png)

4.  **Read the metadata.** Select a row to inspect its full metadata, and
    follow the links between tables to trace an entry through the dataset.

> **Tip:** To pull down the latest entries added by collaborators before
> searching, run a **Sync** (or relaunch with `pulakat.startup`) so your
> local tables reflect the current cloud state.

---

## Adding New Entries

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

4.  **Validate and edit** the new entries (see
    [Editing Metadata](#editing-metadata)) to catch problems before they're
    committed.

5.  **Commit and sync.** On the **Dataset** table, run **Sync** (see
    [Syncing with the Cloud](#syncing-with-the-cloud)). This creates the
    official NDI documents, establishes immutable UIDs, and uploads everything.

> **Heads up:** **Import** actions on the Session table accept a single
> session at a time. Most other table methods support selecting multiple
> entries for batch processing.

---

## Editing Metadata

Fix and finalise entries *before* they sync — once an entry is uploaded to the
cloud its metadata is locked.

1.  **Validate first.** Run **Validate** on the Subject or File table for a
    "dry run" that checks metadata against project requirements and ontology
    rules — missing files, bad data types, broken subject links. Nothing is
    written, so it's safe to run as often as you like.

    ![Validating subject metadata before syncing](images/validate-entries.png)

2.  **Edit to correct.** Use **Edit** (Subject table) to open the metadata
    editor and fix whatever Validate flagged.

3.  **Document to finalise.** **Document** creates the official NDI subject or
    file documents and assigns immutable UIDs. After this, **Sync** uploads
    them. Documented/synced entries are locked — to change one, you'd remove
    and re-import it.

> Subjects also have **Merge Duplicates**, which combines entries that share
> identification metadata — handy when the same animal was imported twice.

---

## Exporting Data

Get metadata or data files back out of the dataset, for analysis or sharing.

- **Export metadata to CSV.** On the **Session** or **Subject** table, use
  **Export > Metadata** to write the selected entries' metadata to a CSV file.
- **Export the data files.** Use **Export > Files** (Session/Subject) or
  **Export** (File table) to copy the underlying data files, along with their
  metadata, to a location you choose.

Most export actions accept multiple selected entries, so you can export a
whole session's worth at once.

---

## Removing Entries

Remove an entry from the local tables with **Remove** (available on the
Dataset, Session, Subject, and File tables).

- For **not-yet-synced** entries, Remove deletes the local entry (and, for
  subjects/files, the associated local data files).
- A removed **session** is also unlinked from the NDI dataset.
- File entries can only be removed while they're **not yet synced** to the
  cloud.

> Removing is local. To reflect a removal in the cloud copy, follow it with a
> **Sync**.

---

## Syncing with the Cloud

**Sync** (on the **Dataset** table) is how your local work and the cloud copy
stay in step. It's a **two-way** operation: it downloads remote updates
(entries added by collaborators) *and* uploads your new documents.

Run a Sync when you:

- **start a session** — `pulakat.startup` syncs automatically on launch, so
  you begin with the latest cloud state;
- **finish adding or editing entries** — to publish your changes and lock them
  in; or
- **want collaborators' latest work** — to pull down entries added elsewhere.

If a sync hangs on startup, see
[If startup is hanging](#if-startup-is-hanging).

---

## Getting Help

If anything breaks, hangs, behaves unexpectedly, or just confuses you, let us
know — we'll respond right away.

**[File an issue](https://github.com/Waltham-Data-Science/nansen-pulakat/issues)**
on the GitHub repository. Click **New issue**, describe what you were doing and
what happened, and submit. This works well whether you've hit a bug or want to
request a feature, and it keeps the conversation tracked publicly.

What helps us help you faster:

- **Screenshots** of the GUI showing the problem.
- **Any `[NDI:...]` warnings or errors** copied from the MATLAB Command
  Window — a single line is often enough to point us straight to the cause.
- **What you were doing** when it happened (which table, which menu action).

---

For a full list of every method on each table, see the
**[Reference](reference.md)**.
