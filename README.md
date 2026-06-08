# nansen-pulakat: Data Management System

[![MATLAB Tests](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml)
[![codecov](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat/branch/main/graph/badge.svg)](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat)

This repository provides a database system that enables the organization and cloud syncing of experimental sessions, subjects, and files. It provides a graphical user interface (GUI) for managing research data and ensuring it is securely backed up and accessible.

## Documentation

| Guide | What's in it |
| :--- | :--- |
| **[Getting&nbsp;Started](docs/getting-started.md)** | Requirements, first-time setup, signing in to NDI cloud, fixing a partial install, and updating to the latest version. Start here. |
| **[User Guide](docs/user-guide.md)** | Launching the app, finding and adding entries, editing metadata, exporting data, and syncing with the cloud. |
| **[Reference](docs/reference.md)** | A full list of every action on the Dataset, Session, Subject, and File tables, plus a plain-language [glossary](docs/reference.md#glossary) of common terms. |

Hit a problem or have a request? See **[Getting Help](docs/user-guide.md#getting-help)** — the fastest route is to [file an issue](https://github.com/Waltham-Data-Science/nansen-pulakat/issues).

## For Developers

Standard MATLAB help blocks are available for all core integration functions.

```matlab
help ndi.nansen.import.subject
help ndi.nansen.fun.getIdentifier
help ndi.nansen.sync.status
help ndi.nansen.sync.repo
help ndi.nansen.startup
```

For scripted / CI contexts where the GUI must not open, launch headless
(requires that you're already authenticated with NDI cloud, e.g. via a prior
interactive `ndi.cloud.uilogin`):

```matlab
pulakat.startup('Headless', true)
```
