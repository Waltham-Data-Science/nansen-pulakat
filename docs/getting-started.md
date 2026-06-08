# Getting Started

This guide takes you from a clean machine to a running Nansen GUI. If you've
already installed and just need to launch the app, see the
[User Guide](user-guide.md).

## Requirements

- **MATLAB R2023a or newer.** R2025a and R2026a get a modernised
  metatable backend (web-based uitable, drag-to-resize columns) via
  the `entity-table` dependency that `install.m` clones for you;
  pre-R2025a uses the legacy Java backend automatically.
- **An NDI cloud account.** The installer's last step prompts you to
  sign in via `ndi.cloud.uilogin`. If you don't have one yet, request
  one from the [NDI cloud admin](https://ndi-cloud.com) before running
  `install.m` — the installer can still finish without an account, but
  the dataset sync step will be skipped.
- **Disk space** for the dataset cache. The cloud dataset downloads
  into `~/ndi/data/<cloudDatasetID>/` on first launch and grows with
  the dataset. Plan for a few times the size of the cloud dataset
  (the binaries plus a SQLite index) — a 50 GB cloud dataset
  comfortably fits in 100 GB local.

## First Time Setup

1.  **Install Git** if you don't already have it.
    - **Windows:** Download from [git-scm.com](https://git-scm.com/download/win).
    - **Mac:** Open Terminal and run `xcode-select --install`.
    - **Linux:** Use your distribution's package manager.

2.  **Download and run `install.m`.** There are two equivalent ways — pick whichever is more convenient. The installer will clone the dependencies, set up your MATLAB paths, sync with the NDI cloud, and open the Nansen GUI.

    **Option A — From MATLAB (recommended).** Open MATLAB and paste this snippet into the Command Window:

    ```matlab
    cd(tempdir)
    url = 'https://raw.githubusercontent.com/Waltham-Data-Science/nansen-pulakat/main/install.m';
    websave('install.m', url);
    install
    ```

    This downloads `install.m` to MATLAB's temp folder and runs it — no browser steps required.

    **Option B — From your browser.** Visit the [install.m page on GitHub](https://github.com/Waltham-Data-Science/nansen-pulakat/blob/main/install.m), click the **Download raw file** button on the right side of the file's toolbar, then in MATLAB:

    ```matlab
    cd('~/Downloads')   % or wherever the file was saved
    install
    ```

3.  **Sign in to NDI cloud** when prompted. The installer ends with
    an `ndi.cloud.uilogin` dialog; enter the email and password for
    your NDI cloud account. The credentials persist for subsequent
    MATLAB sessions until you log out.

## If the install fails partway

`install.m` is **idempotent** — re-running it picks up where the
previous attempt left off. The most common partial-install signals
and what to do:

- **Network errors during a `git clone`.** Re-run `install`. Already-
  cloned repos are detected and pulled instead of re-cloned.
- **`Could not save MATLAB path to ...`.** Your `userpath` is read-
  only. Find a writable folder, set `userpath` to it
  (`userpath('/some/writable/path')`), then re-run `install`.
- **`matlab.apps.AppBase ... cannot be found on MATLAB's search
  path`** on R2026a. The installer's path-restore step
  (PR #45) should have prevented this; if it still appears, run
  `restoredefaultpath; rehash` then re-run `install`.

If none of those apply, delete `~/ndi/tools/` and `<userpath>/pathdef.m`
and start over. Still stuck? See [Getting Help](user-guide.md#getting-help).

## Updating to the latest version

Re-run `install.m`. The installer detects the existing checkouts and
runs `git pull` on each instead of re-cloning. No need to wipe state
or re-authenticate.

---

Once you're installed, head to the **[User Guide](user-guide.md)** to launch
the app and start working with your data.
