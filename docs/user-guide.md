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

> **Unsure what a word means?** See the
> [Glossary](reference.md#glossary) for plain-language definitions of terms
> like *session*, *validate*, and *sync*.

---

## The Big Picture

This app keeps your experimental data organised and safely backed up. The
everyday flow is four steps:

```
   Collect    →    Import    →     Check     →     Sync
  data in the     it into the    it over for      it to the
     lab             app          mistakes          cloud

   (recordings,   (sessions,     (Validate &      (backed up &
    animals,       subjects,        Edit)          shareable
    files)         files)                          with the lab)
```

You collect data during an experiment, **import** it into the app so it's
catalogued, **check** it for mistakes, and **sync** it to the cloud so it's
backed up and your collaborators can see it. Most of your time is spent in the
middle two steps. The rest of this guide walks through each one.

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

**You'll know it worked when** the app window opens showing the Dataset table.

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

The tables are nested: a dataset holds sessions, a session holds subjects, and
a subject holds files. You switch between them with the table selector, and you
can follow the links between them — a session lists its subjects, a subject
lists its files — to trace any entry up or down the hierarchy.

---

## Searching for Entries

**Goal:** find existing sessions, subjects, or files — for example, to check
whether an animal has already been imported, or to see every file linked to one
session.

**Steps:**

1.  **Pick the right table** with the table selector. Each row is one entry.

2.  **Sort by a column.** Click a column header to sort A–Z; click again for
    Z–A. Useful for grouping entries by subject, date, or data type.

3.  **Filter to narrow the list.** Open the column filter to show only rows
    matching a value (e.g. a subject ID or a file type). Combine filters
    across columns to drill down.

4.  **Click a row** to see its full details, and follow the links between
    tables to trace an entry through the dataset.

**You'll know it worked when** the table shows only the rows matching what you
filtered for.

> **Tip:** To see the latest entries added by collaborators before searching,
> run a **Sync** (or relaunch with `pulakat.startup`) so your tables reflect
> what's in the cloud.

---

## Adding New Entries

**Goal:** get new experimental data into the app and backed up to the cloud.

**Steps** — work through them in order; each one builds on the last:

1.  **Import a session.** On the **Dataset** table, choose
    **Import > Session**, pick the session's folder, and give it a unique
    name. This adds one experimental session (a day / recording).

2.  **Import subjects.** On the **Session** table, use
    **Import > Subjects > Files** to detect animals automatically from
    `animal_mapping.csv`, or **Import > Subjects > Manual** to type
    subject names in by hand.

3.  **Import data files.** Still on the **Session** table, use
    **Import > Data > Folder** to scan the session folder for supported
    file types, or **Import > Data > Files** to pick specific files and
    say which data type and subject each belongs to.

4.  **Check your work.** Validate and fix the new entries before they're
    finalised — see [Editing Metadata](#editing-metadata).

5.  **Sync to the cloud.** On the **Dataset** table, run **Sync** to back
    everything up — see [Syncing with the Cloud](#syncing-with-the-cloud).

**You'll know it worked when** the new session, subjects, and files appear as
rows in their tables.

> **Heads up:** the **Import** actions take one session at a time. Most other
> actions let you select several entries at once for batch processing.

---

## Editing Metadata

**Goal:** fix and finalise entries *before* they sync. Once an entry is backed
up to the cloud, its details are locked.

**Steps:**

1.  **Validate first.** Run **Validate** on the Subject or File table for a
    safe "practice run" that checks each entry for problems — missing files,
    wrong data types, an animal that isn't linked to anything. It only reports;
    it changes nothing, so run it as often as you like.

2.  **Edit to fix.** Use **Edit** (Subject table) to open the editor and
    correct whatever Validate flagged.

3.  **Finalise.** **Document** files the entry permanently into the database,
    and **Sync** backs it up to the cloud. Once an entry is finalised it's
    locked — to change it after that, you'd remove it and import it again.

**You'll know it worked when** Validate comes back with no problems reported.

> Subjects also have **Merge Duplicates**, which combines entries for the same
> animal — handy when one got imported twice.

---

## Exporting Data

**Goal:** get metadata or data files back out of the app, for analysis or
sharing.

**Steps** — pick whichever you need:

- **Export metadata to a spreadsheet.** On the **Session** or **Subject**
  table, use **Export > Metadata** to save the selected entries' details to a
  CSV file (opens in Excel or any spreadsheet program).
- **Export the data files themselves.** Use **Export > Files**
  (Session/Subject) or **Export** (File table) to copy the actual data files,
  with their details, to a folder you choose.

You can select several entries first, so you can export a whole session's worth
at once.

**You'll know it worked when** the CSV file or copied data files appear in the
folder you chose.

---

## Removing Entries

**Goal:** delete an entry you no longer want.

**Steps:** select the entry and choose **Remove** (available on the Dataset,
Session, Subject, and File tables). What happens depends on whether it's been
synced yet:

- For entries **not yet synced**, Remove deletes the entry (and, for subjects
  and files, the local copies of their data files).
- Removing a **session** also unlinks it from the dataset.
- A **file** can only be removed while it's **not yet synced** to the cloud.

**You'll know it worked when** the entry disappears from the table.

> Removing only affects your computer. To remove it from the cloud copy too,
> run a **Sync** afterwards.

---

## Syncing with the Cloud

**Goal:** keep the copy on your computer and the cloud copy matched up.

**Sync** (on the **Dataset** table) works **both ways** at once: it downloads
anything new from the cloud (entries your collaborators added) *and* uploads
your new work.

Run a Sync when you:

- **start work** — `pulakat.startup` syncs automatically when you launch, so
  you begin with the latest;
- **finish adding or editing entries** — to back up your changes and lock them
  in; or
- **want your collaborators' latest work** — to pull down what they've added.

**You'll know it worked when** Sync finishes without an error and your new
entries are reflected on both sides.

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
