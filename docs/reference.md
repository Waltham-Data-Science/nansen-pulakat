# Reference

Each table's actions live in the **Methods** menu in the menu bar at the top of
the window. The actions shown change with whichever table is active. Select one
or more entries, then open **Methods** and choose the action; the indentation
below matches the submenu nesting (for example, **Methods > Import > Subjects >
Files**). For task walkthroughs that use these actions, see the
[User Guide](user-guide.md); for plain-language definitions of terms, see the
[Glossary](#glossary) at the end.

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
    - **Files** — Detects and imports subjects automatically from a lab-standard `animal_mapping` file (`.csv`, `.xls`, or `.xlsx`).
    - **Manual** — Opens a dialog to type subject names in by hand.
  - **Data**
    - **Folder** — Scans the session folder for supported file types and imports them.
    - **Files** — Lets you pick specific files and say which data type and subject each belongs to.
- **Export**
  - **Metadata** — Saves the selected session's details to a CSV (spreadsheet) file.
  - **Files** — Saves a metadata CSV and copies the session's data files. Only **documented** files have data to copy.
- **Remove** — Removes the selected session from your computer and unlinks it from the dataset (only before the session is synced to the cloud).

## Subject Table

- **Validate** — A safe "practice run" that checks subject details against the project's requirements and reports any problems, without changing anything.
- **Edit** — Opens an editor for the subject's details (locked once the subject is documented).
- **Document** — Files the subject permanently into the database, giving it a permanent ID.
- **Merge Duplicates** — Combines duplicate entries for the same animal, matched on shared identifying details.
- **Export**
  - **Metadata** — Saves the selected subjects' details to a CSV (spreadsheet) file.
  - **Files** — Saves a metadata CSV and copies the subjects' data files. Only **documented** files have data to copy.
- **Remove** — Deletes the subject entry and its local data files from your computer (only before the subject is documented).

## File Table

- **Validate** — Checks that each file actually exists, has a valid data type, and is linked to a subject.
- **Document** — Files the data file permanently into the database, giving it a permanent ID. A file can only be documented once all of its subjects are documented.
- **Export** — Saves a metadata CSV for the selected files and copies their data files. Only **documented** files have data to copy; undocumented files appear in the CSV but their file is skipped.
- **Remove** — Removes the file entry from your computer (only before the file is documented).

## Import File Formats

### The `animal_mapping` subject file

**Import > Subjects > Files** reads a file named `animal_mapping` (`.csv`,
`.xls`, or `.xlsx`) with one row per animal. Give it these columns:

| Column | What it holds |
| :--- | :--- |
| **Strain** | The animal's strain. |
| **BiologicalSex** | The animal's biological sex. |
| **Animal** | The enumerated animal identifier. |
| **Cage** | The cage identifier. |
| **Label** | The text label / identifier. |
| **Treatment** | The treatment given. |

(The subject's overall identifier and electronic file name are generated for
you, so you don't add columns for them.)

### Recognised data file types

**Import > Data > Folder** assigns a type to each file by what its **name
contains** (case-insensitive); the first match wins:

| If the filename contains | Imported as |
| :--- | :--- |
| `schedule` | experiment metadata file |
| `DIA` | data-independent acquisition (DIA) |
| `.svs` | slide scanner image acquisition |
| `.bimg`, `.pimg`, `.mxml`, `.vxml` | echocardiogram acquisition |

A file that matches none of these is imported as "unknown electronic file
type." You can always set a file's type by hand with **Import > Data > Files**.

## Glossary

Plain-language meanings for terms you'll see in the app and these docs:

| Term | What it means |
| :--- | :--- |
| **Dataset** | Your whole collection of data — the thing that backs up to the cloud. |
| **Session** | One experimental session, e.g. a single day or recording. |
| **Subject** | One animal, belonging to a session. |
| **File** | A data file (such as `.svs` or `.bimg`) belonging to a subject. |
| **Entry** | Any single row in a table — a session, subject, or file. |
| **Metadata** | The descriptive details about an entry (names, dates, types) — not the data file itself. |
| **Import** | Bring data into the app so it's catalogued. |
| **Validate** | A safe check that looks for problems and reports them without changing anything. |
| **Document / Finalise** | File an entry permanently into the database so it's official. |
| **Sync** | Match your computer's copy with the cloud copy — uploading and downloading at once. |
| **The cloud** | The online storage (NDI cloud) where your data is backed up and shared with the lab. |
| **Command Window** | The panel in MATLAB where you type commands like `pulakat.startup`. |
