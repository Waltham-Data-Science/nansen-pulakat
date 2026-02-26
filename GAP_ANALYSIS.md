# Strategic Audit: Structural Gap Analysis (NANSEN-NDI Integration)

This report identifies the structural discrepancies between the current repository state and the approved **ARCHITECTURE_REDESIGN.md** (4-Tier Hierarchy & UID Tethering).

## 1. Hierarchy Audit: 2-Tier vs. 4-Tier

*   **Current State:** The codebase follows a loosely coupled model where **Sessions**, **Subjects**, and **Files** are largely treated as sibling entities linked by shared metadata strings (e.g., `SessionName`).
*   **The Gap:** There is no structural enforcement of the **Dataset > Session > Subject > File** ownership.
    *   `ndi.nansen.metatable.subject.m` and `file.m` query the database for global types without requiring a parent UID context.
    *   A Subject is not explicitly "owned" by a Session UID; it is merely associated with a session name string.
*   **Required Shift:** Transition to a model where a Subject instance exists in NDI *only* as a child of a specific Session UID.

## 2. Tethering Gap: Transient Identity vs. Immutable UIDs

*   **Current State:** Identity is derived from transient metadata using `ndi.nansen.fun.getIdentifier.m` (concatenating strings like Session, Cage, and Filename).
*   **"Guessing" Functions:**
    *   **`ndi.nansen.metatable.add.m`**: The primary upsert logic. It uses these fragile composite strings to find matching rows. If a user renames a cage, the system "guesses" it is a new record, causing duplicates.
    *   **`ndi.nansen.fun.matchTables.m`**: Used across the integration to find corresponding rows via name-matching.
*   **The Gap:** The `DocumentIdentifier` (NDI ID) is treated as a metadata field filled *after* sync, rather than the primary anchor for the local-to-master relationship.

## 3. Refactor vs. Retire Report

| Component | Status | Reasoning |
| :--- | :--- | :--- |
| **`ndi.nansen.fun.getIdentifier.m`** | **REFACTOR** | Transition from a "Composite String Generator" to a "Random UUID Factory" for the Birth of the Tether. |
| **`ndi.nansen.metatable.add.m`** | **REFACTOR** | Restructure for Sequential Commitment (Session -> Subject -> File) using UID-only matching. |
| **`ndi.nansen.import.file.createDocuments.m`** | **REFACTOR** | Enforce Strict Schema Mapping and mandatory `parent_subject_uid` dependency. |
| **`getIdentifier` (Legacy Logic)** | **RETIRE** | Logic that builds identity from metadata fields (Name, Date) must be bypassed for all new records. |
| **Name-Based Matching** | **RETIRE** | Bypassing fallback logic in `add.m` once a record has an established NDI Tether. |

## 4. Framework Compliance Check

*   **Direct Table Manipulation:** `ndi.nansen.metatable.add.m` correctly uses `metaTable.editEntries` for values but uses direct table assignment (`existingTable.(varName) = ...`) for schema alignment workarounds. These must be replaced with official Nansen schema methods.
*   **Constructor Usage:** `ndi.nansen.import.file.createDocuments.m` is framework-compliant (uses `ndi.document`) but lacks the **Validation Gate** to block unmapped metadata.
