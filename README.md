# nansen-pulakat: Data Management System

[![MATLAB Tests](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml/badge.svg)](https://github.com/Waltham-Data-Science/nansen-pulakat/actions/workflows/matlab-tests.yml)
[![codecov](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat/branch/main/graph/badge.svg)](https://codecov.io/gh/Waltham-Data-Science/nansen-pulakat)

This repository provides a database system that enables the organization and cloud syncing of experimental sessions, subjects, and files. It provides a graphical user interface (GUI) for managing research data and ensuring it is securely backed up and accessible.

## Documentation

| Guide | What's in it |
| :--- | :--- |
| **[Getting&nbsp;Started](docs/getting-started.md)** | Requirements, first-time setup, signing in to NDI cloud, fixing a partial install, and updating to the latest version. Start here. |
| **[User Guide](docs/user-guide.md)** | Launching the app day to day, the two everyday tasks (**searching for records** and **adding new records**) with screenshots, and a full reference for every table method. |

## For Developers

Standard MATLAB help blocks are available for all core integration functions.

```matlab
help ndi.nansen.import.subject
help ndi.nansen.fun.getIdentifier
help ndi.nansen.sync.status
help ndi.nansen.sync.repo
help ndi.nansen.startup
```
