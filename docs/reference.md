# Reference

The lists below mirror the **Methods** menu for each table — the indentation
matches the dropdown you click through when an entry is selected. For task
walkthroughs that use these methods, see the [User Guide](user-guide.md).

**Note on selection:** Most actions let you select several entries at once to
process them together. The **Import** actions are the exception — they take one
session at a time.

## Dataset Table

- **Import**
  - **Session** — Pick a session's folder and give it a unique name to add it to the dataset.
- **Sync** — Matches your computer's copy with the cloud, both ways at once: downloads others' updates and uploads your new work.

## Session Table

- **Import**
  - **Subjects**
    - **Files** — Detects and imports subjects automatically from lab-standard files (e.g. `animal_mapping.csv`).
    - **Manual** — Opens a dialog to type subject names in by hand.
  - **Data**
    - **Folder** — Scans the session folder for supported file types and imports them.
    - **Files** — Lets you pick specific files and say which data type and subject each belongs to.
- **Export**
  - **Metadata** — Saves the selected session's details to a CSV (spreadsheet) file.
  - **Files** — Copies all data files belonging to the selected session.
- **Remove** — Removes the selected session from your computer and unlinks it from the dataset.

## Subject Table

- **Validate** — A safe "practice run" that checks subject details against the project's requirements and reports any problems, without changing anything.
- **Edit** — Opens an editor for the subject's details (locked once the entry is synced to the cloud).
- **Document** — Files the subject permanently into the database, giving it a permanent ID.
- **Merge Duplicates** — Combines duplicate entries for the same animal, matched on shared identifying details.
- **Export**
  - **Metadata** — Saves the selected subjects' details to a CSV (spreadsheet) file.
  - **Files** — Copies all data files belonging to the selected subjects.
- **Remove** — Deletes the subject entry and its local data files from your computer.

## File Table

- **Validate** — Checks that each file actually exists, has a valid data type, and is linked to a subject.
- **Document** — Files the data file permanently into the database, giving it a permanent ID.
- **Export** — Copies the selected data files along with their details.
- **Remove** — Removes the file entry from your computer (only while it's not yet synced to the cloud).
