## nansen-pulakat

First time:

1. Make sure `git` is installed on your machine. If it is not, on Windows, go [here](https://git-scm.com/download/win). On Mac, open a terminal, and type `xcode-select --install`. Accept the license and wait for install. On Linux, consult your Linux distribution's package manager.
2. Download the file [![download](https://img.shields.io/badge/_-install.m-blue?logo=github)](https://github.com/Waltham-Data-Science/nansen-pulakat/raw/main/install.m). Note: If the link opens as text in your browser, simply press Ctrl+S (or Cmd+S) and save it to your computer as `install.m`.
3. Run `install.m` in MATLAB.

Subsequent uses:

Run `pulakat.startup` to open the GUI.

### Using the GUI

This repository provides a graphical user interface (GUI) for managing experimental data. Below are instructions for common tasks.

#### 1. Adding a Session
A "Session" represents a single experimental session (e.g., a specific day or recording).
1. Open the **Dataset** table from the main menu.
2. Select your dataset from the list.
3. In the **Methods** menu, select **Import > Session**.
4. Follow the prompts to select the session directory.

#### 2. Adding Subjects
Subjects (animals) can be added to a session automatically from metadata files or manually.
1. In the **Dataset** table, select your dataset.
2. In the **Methods** menu, select **Import > Subjects > Auto** to automatically find subjects in the session folder.
3. Alternatively, select **Import > Subjects > Manual** to enter subject details (ID, Cage, Label, etc.) through a dialog.
*Note: Subjects will not be added if required identification fields are missing.*

#### 3. Adding Files
Experimental data files (images, metadata, etc.) can be added to subjects.
1. Navigate to the **Subject** table (you can do this by selecting a session and viewing its subjects).
2. Select one or more subjects.
3. In the **Methods** menu, select **Import > Files > Auto** to automatically scan for files in the session directory.
4. Or select **Import > Files > Manual** to pick specific files from your computer and assign them a data type and subject.

#### 4. Editing and Deleting
- **To Edit:** Select the record you wish to change and find the **Edit** option in the **Methods** menu. A dialog will appear where you can update metadata.
- **To Delete:** Select the records you wish to remove, and in the **Methods** menu, select **Remove**.
*Note: Records that have already been synced to the cloud cannot be deleted or edited.*

#### 5. Syncing to the Cloud
Syncing ensures your local data is backed up and available to other lab members.
1. Go to the **Dataset** table.
2. Select the dataset you want to sync.
3. In the **Methods** menu, select **Sync**.
4. The system will upload new files and metadata to the cloud.
