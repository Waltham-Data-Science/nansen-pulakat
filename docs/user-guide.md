# User Guide

How to launch the app and work with your data day to day. If you haven't
installed yet, start with [Getting Started](getting-started.md). For a full
list of what every menu action does, see the [Reference](reference.md).

- [The Big Picture](#the-big-picture)
- [Launching the App](#launching-the-app)
- [Understanding the Tables](#understanding-the-tables)
- [Searching for Entries](#searching-for-entries)
- [Adding New Entries](#adding-new-entries)
- [Editing Metadata](#editing-metadata)
- [Exporting Data](#exporting-data)
- [Removing Entries](#removing-entries)
- [Syncing with the Cloud](#syncing-with-the-cloud)
- [Getting Help](#getting-help)

> [!TIP]
> Unsure what a word means? See the
> [Glossary](reference.md#glossary) for plain-language definitions of terms
> like *session*, *validate*, and *sync*.

---

## The Big Picture

This app keeps your experimental data organised and safely backed up. The
everyday flow is five steps:

```
 Collect   →   Import   →   Check    →  Finalise  →    Sync
 data in      into the     Validate    Document      upload to
 the lab        app         & Edit     (locks it)    the cloud

 recordings,  sessions,    fix any     make it       backed up &
 animals,     subjects,    mistakes    permanent     shareable
 files        files                                  with the lab
```

You collect data during an experiment, **import** it into the app so it's
catalogued, **check** it for mistakes (Validate & Edit), **document** it to
make it a permanent record, and **sync** it to the cloud so it's backed up and
your collaborators can see it. Checking and fixing is where you'll spend most
of your time — and it has to happen *before* you document, because documenting
locks an entry. The rest of this guide walks through each step.

---

## Launching the App

Every time you want to use the app, open MATLAB and type this into the
Command Window (the large panel where you type commands), then press Enter:

```matlab
pulakat.startup
```

This pulls the latest data down from the cloud and opens the app window. Just
restarting MATLAB makes the app *available* but doesn't fetch cloud updates —
running `pulakat.startup` is what does that.

> ✅ **You'll know it worked when** the app window opens showing the Dataset
> table.

### If startup is hanging

If launching seems stuck on "syncing" (a slow upload or network hiccup), you
can skip the sync and open the app against the copy already on your computer:

```matlab
pulakat.startup('SkipCloudSync', true)
```

You can still sync later, by hand, with the **Sync** action on the Dataset
table.

---

## Understanding the Tables

Your data is organised into four tables, each one a level of detail below the
last:

| Table | What one entry is |
| :--- | :--- |
| **Dataset** | The whole collection — the thing that syncs to the cloud. |
| **Session** | A single experimental session. |
| **Subject** | An animal within a session. |
| **File** | A data file (`.svs`, `.bimg`, …) linked to a subject. |

The tables are nested in meaning: a dataset is made up of sessions, a session
has subjects, and a subject has files. Switch between them using the buttons —
**Dataset**, **File**, **Session**, **Subject** — down the left side of the
window.

There's no clickable link from one table to another. To find the entries
related to a row — say, all the subjects in a session — switch to that table
and filter by the shared identifier (see [Searching for Entries](#searching-for-entries)).

---

## Searching for Entries

**Goal:** find existing sessions, subjects, or files — for example, to check
whether an animal has already been imported, or to see every file linked to one
session.

**Steps:**

1.  **Pick the right table** using the buttons on the left
    (Dataset / File / Session / Subject). Each row is one entry, and its
    columns hold that entry's details.

2.  **Sort by a column.** Click a column header to sort by it; click again to
    reverse the order. Useful for grouping entries by subject, date, or data
    type.

3.  **Filter to narrow the list.** Each column can be filtered to show only the
    rows matching a value (e.g. a subject ID or a file type). Open a column's
    filter from its header — on older versions of MATLAB, press and hold the
    header. Filter on more than one column to drill down.

4.  **Read the details** in the row's columns. To jump to related entries —
    a session's subjects, a subject's files — switch to that table (left-hand
    buttons) and filter by the shared identifier.

> ✅ **You'll know it worked when** the table shows only the rows matching what
> you filtered for.

> [!TIP]
> To see the latest entries added by collaborators before searching, run a
> **Sync** (or relaunch with `pulakat.startup`) so your tables reflect what's
> in the cloud.

---

## Adding New Entries

**Goal:** get new experimental data into the app and backed up to the cloud.

**Steps** — work through them in order; each one builds on the last. Every
action below is in the **Methods** menu, and the actions on offer change with
whichever table is active.

1.  **Import a session.** With the **Dataset** table active, choose
    **Methods > Import > Session**, pick the session's folder, and give it a
    unique name. This adds one experimental session (a day / recording).

2.  **Import subjects.** Switch to the **Session** table and use
    **Methods > Import > Subjects > Files** to detect animals automatically
    from a lab-standard `animal_mapping` file (`.csv`, `.xls`, or `.xlsx`), or
    **Methods > Import > Subjects > Manual** to type subject names in by hand.
    See [the `animal_mapping` file format](reference.md#the-animal_mapping-subject-file)
    for the columns it needs.

3.  **Import data files.** Still on the **Session** table, use
    **Methods > Import > Data > Folder** to scan the session folder for
    supported file types, or **Methods > Import > Data > Files** to pick
    specific files and say which data type and subject each belongs to.
    See [recognised data file types](reference.md#recognised-data-file-types)
    for what the folder scan picks up.

4.  **Check, then document.** Validate and fix the new entries, then
    **Document** them to make them permanent — see
    [Editing Metadata](#editing-metadata). Do this *before* the next step,
    because documenting is what locks an entry in.

5.  **Sync to the cloud.** With the **Dataset** table active, run
    **Methods > Sync** to upload everything — see
    [Syncing with the Cloud](#syncing-with-the-cloud).

> ✅ **You'll know it worked when** the new session, subjects, and files appear
> as rows in their tables.

> [!NOTE]
> The **Import** actions take one session at a time. Most other actions let you
> select several entries at once to process them together.

---

## Editing Metadata

**Goal:** get entries right *before* you document them.

> [!WARNING]
> **Documenting locks an entry.** Once you run **Document** on a subject or
> file (step 3) it becomes a permanent record — you can no longer edit it, and
> you can't remove it either. There's no unlock. So validate and fix everything
> *before* you document. (Documenting happens locally, before **Sync** uploads
> it — the lock is at Document, not Sync.)

**Steps:**

1.  **Validate first.** Run **Methods > Validate** on the Subject or File table
    for a safe "practice run" that checks each entry for problems — missing
    files, wrong data types, an animal that isn't linked to anything. It only
    reports; it changes nothing, so run it as often as you like.

2.  **Edit to fix.** Use **Methods > Edit** (Subject table) to open the editor
    and correct whatever Validate flagged.

3.  **Finalise.** **Document** files the entry permanently into the database,
    and **Sync** backs it up to the cloud.

> [!IMPORTANT]
> **Document subjects before files.** A file can only be documented once *all*
> of its related subjects are documented. If you try to document a file first,
> validation stops you with "This subject must first be documented." So finalise
> your subjects, then your files.

> ✅ **You'll know it worked when** Validate comes back with no problems
> reported.

> [!TIP]
> **Quick edits by double-click.** On the **Subject** table you can edit some
> fields directly: double-click the cell and a small dialog opens for the new
> value. This works for a subject's identifier, cage, and enumerated ID, and
> for its treatment, strain, and biological sex. The change propagates
> automatically to the related Session or File entries. As with **Edit**, this
> only works *before* the subject is documented — once it is, you'll get a
> "cannot be edited" message.

> [!NOTE]
> Subjects also have **Merge Duplicates**, which combines entries for the same
> animal — handy when one got imported twice.

---

## Exporting Data

**Goal:** get metadata or data files back out of the app, for analysis or
sharing.

**Steps** — pick whichever you need:

- **Export metadata to a spreadsheet.** On the **Session** or **Subject**
  table, use **Methods > Export > Metadata** to save the selected entries'
  details to a CSV file (opens in Excel or any spreadsheet program).
- **Export the data files themselves.** Use **Methods > Export > Files**
  (Session/Subject) or **Methods > Export** (File table) to copy the actual
  data files, with their details, to a folder you choose.

You can select several entries first, so you can export a whole session's worth
at once.

> [!IMPORTANT]
> **Only documented files have data to export.** The metadata CSV always
> includes every selected file, but the actual data file is only copied for
> files you've **documented**. An in-progress file shows up as a row in the CSV,
> but its file is skipped.

> ✅ **You'll know it worked when** the CSV file or copied data files appear in
> the folder you chose.

---

## Removing Entries

**Goal:** delete an entry you no longer want.

**Steps:** select the entry and choose **Methods > Remove**. You can only
remove an entry that hasn't been finalised yet, and "finalised" means something
slightly different per table:

- A **subject** or **file** can be removed only **before it's documented**.
  Once documented, it's locked. Removing deletes the entry and its local data
  files.
- A **session** can be removed only **before it's synced to the cloud**.
  Removing it also unlinks it from the dataset and deletes its local data.

> ✅ **You'll know it worked when** the entry disappears from the table.

> [!NOTE]
> Because you can only remove entries that haven't been finalised, removal is
> always local — there's never a cloud copy to clean up. Documented or synced
> entries can't be removed at all.

---

## Syncing with the Cloud

**Goal:** keep the copy on your computer and the cloud copy matched up.

**Methods > Sync** (on the **Dataset** table) works **both ways** at once: it
downloads anything new from the cloud (entries your collaborators added) *and*
uploads your new work.

> [!IMPORTANT]
> **Only documented entries are synced.** Sync uploads your **documents** — the
> entries you've finalised with **Document**. Anything still in progress
> (imported but not yet documented) stays on your computer and is ignored by
> Sync until you document it. So nothing reaches the cloud until you've
> documented it.

Run a Sync when you:

- **start work** — `pulakat.startup` syncs automatically when you launch, so
  you begin with the latest;
- **finish adding or editing entries** — to back up your work to the cloud; or
- **want your collaborators' latest work** — to pull down what they've added.

> ✅ **You'll know it worked when** Sync finishes without an error and your new
> entries are reflected on both sides.

If syncing seems stuck when launching, see
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

- **Screenshots** of the app showing the problem.
- **Any `[NDI:...]` warnings or errors** copied from the MATLAB Command
  Window — a single line is often enough to point us straight to the cause.
- **What you were doing** when it happened (which table, which menu action).

---

For a full list of every action on each table, see the
**[Reference](reference.md)**.
