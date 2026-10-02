# Linux File Permission Auditor

A Bash-based Linux security auditing tool designed to identify potentially risky file permissions and provide security context for detected files.

The project focuses on a practical Blue Team/SOC workflow:

**Detection → Context → Risk Classification → Package Attribution → Logging → Change Detection**

---

## Project Overview

Linux file permissions are an important part of system security. Misconfigured permissions can allow unauthorized users to modify files or execute programs with elevated privileges.

This project automates several permission checks commonly useful during Linux security assessments.

The auditor scans for:

- World-writable files
- SUID files
- SGID files

For SUID and SGID findings, the tool also attempts to identify the Debian package responsible for the file.

The tool generates timestamped audit logs and maintains a baseline of findings so that changes can be detected between scans.

---

## Security Goals

The project was designed to answer practical security questions such as:

- Which files are writable by other users?
- Which programs have SUID enabled?
- Which programs have SGID enabled?
- Who owns the affected files?
- Which Linux package installed the file?
- Has the system's permission-risk profile changed since the previous scan?
- Are newly introduced findings appearing?

---

## Features

### 1. World-Writable File Detection

The auditor searches for regular files with the world-writable permission bit.

Example:

```text
[HIGH] World-writable file detected
        File: /home/kali/file-permission-lab/public.txt
        Permissions: -rwxrwxrwx
        Owner: kali
        Group: kali
        Risk: Other users can modify this file
````

World-writable files are flagged because other users on the system may be able to modify them.

---

### 2. SUID Detection

The auditor identifies files with the SUID permission bit.

SUID programs can execute with the privileges of the file owner.

Example:

```text
[REVIEW] SUID file detected
        File: /usr/bin/sudo
        Permissions: -rwsr-xr-x
        Owner: root
        Group: root
        Package: sudo
        Status: Package-managed
        Risk: Program can execute with the file owner's privileges
```

SUID findings are classified as `REVIEW` rather than automatically being treated as malicious because legitimate Linux software commonly uses SUID.

---

### 3. SGID Detection

The auditor also identifies files with the SGID permission bit.

Example:

```text
[REVIEW] SGID file detected
        File: /usr/bin/crontab
        Permissions: -rwxr-sr-x
        Owner: root
        Group: crontab
        Package: cron
        Status: Package-managed
        Risk: Program can execute with the file group's privileges
```

---

### 4. Package Attribution

For SUID and SGID files, the auditor uses Debian package information to determine whether the file is managed by an installed package.

Example:

```text
Package: sudo
Status: Package-managed
```

If a file cannot be associated with an installed package, it is reported as:

```text
Package: UNMANAGED / UNKNOWN
Status: Investigate - unmanaged SUID file
```

This provides additional context for security investigation.

---

### 5. Audit Logging

Each execution creates a timestamped audit log in the `logs/` directory.

Example:

```text
logs/
├── audit_2026-10-01_10-37-13.log
├── audit_2026-10-01_10-50-21.log
└── baseline.txt
```

The log contains the scan output, findings, summary, and change-detection results.

---

### 6. Baseline and Change Detection

The auditor maintains a baseline of previously observed findings.

When the auditor runs again, it compares the current findings against the previous baseline.

New findings are reported as:

```text
[NEW] New findings detected:
WORLD-WRITABLE:/path/to/file
```

Findings that are no longer present are reported as:

```text
[REMOVED] Findings no longer detected:
WORLD-WRITABLE:/path/to/file
```

This allows the tool to detect changes in the system's permission-risk profile over time.

---

## Audit Summary

The tool produces a summary similar to:

```text
==================================================
                        AUDIT SUMMARY
==================================================
World-writable files: 1
SUID files:             25
SGID files:             6
==================================================
```

---

## Project Structure

```text
linux-file-permission-auditor/
├── permission_auditor.sh
├── README.md
├── logs/
│   ├── audit_*.log
│   └── baseline.txt
└── pb_data/
```

> `pb_data/` is currently present in the working project directory and should be reviewed before publishing the repository.

---

## Requirements

* Linux
* Bash
* `find`
* `stat`
* `dpkg-query`
* `dpkg`
* Standard Linux command-line utilities

The project was developed and tested in Kali Linux.

---

## Installation

Clone the repository:

```bash
git clone <repository-url>
cd linux-file-permission-auditor
```

Make the script executable:

```bash
chmod +x permission_auditor.sh
```

---

## Usage

Run the auditor:

```bash
./permission_auditor.sh
```

The script displays findings in the terminal while also recording the output in a timestamped log.

---

## Testing

The project was tested using controlled permission changes.

### New Finding Test

A controlled world-writable file was created:

```bash
echo "change detection test" > auditor_test.txt
chmod 666 auditor_test.txt
```

The auditor detected the file as a new finding:

```text
[NEW] New findings detected:
WORLD-WRITABLE:/home/kali/linux-file-permission-auditor/auditor_test.txt
```

### Removed Finding Test

The controlled test file was then removed:

```bash
rm auditor_test.txt
```

The auditor detected that the previous finding was no longer present:

```text
[REMOVED] Findings no longer detected:
WORLD-WRITABLE:/home/kali/linux-file-permission-auditor/auditor_test.txt
```

The system was then returned to its original test state.

---

## Example Security Workflow

A basic investigation workflow using the tool is:

```text
1. Run audit
       ↓
2. Identify risky permissions
       ↓
3. Review ownership
       ↓
4. Identify package attribution
       ↓
5. Determine whether the finding is expected
       ↓
6. Compare against previous baseline
       ↓
7. Investigate unexpected changes
```

The tool is intended to support investigation rather than automatically declare every permission finding malicious.

---

## Limitations

This project is intentionally lightweight and focuses on permission-based auditing.

Current limitations include:

* The world-writable scan is currently limited to the configured lab directories.
* SUID and SGID scans currently focus on `/usr/bin` and `/usr/local/bin`.
* Package attribution depends on Debian package metadata.
* The tool does not determine whether a finding is actually exploitable.
* The tool does not automatically remediate insecure permissions.
* The tool does not replace a full host-based security monitoring or vulnerability-management solution.

---

## Security Considerations

SUID and SGID files are not automatically malicious.

Linux systems commonly contain legitimate SUID and SGID programs. Therefore, findings should be evaluated using additional context such as:

* File ownership
* File location
* Package attribution
* Expected system configuration
* Recent changes
* Organizational security policy

The auditor is designed to surface items for investigation.

---

## Skills Demonstrated

This project demonstrates practical experience with:

* Linux file permissions
* Bash scripting
* Linux security auditing
* SUID and SGID analysis
* File ownership analysis
* Debian package attribution
* Security logging
* Baseline comparison
* Change detection
* Security-focused command-line tooling
* Blue Team investigation concepts

---

## Future Improvements

Potential future improvements include:

* Configurable scan directories
* More robust handling of filenames containing spaces
* Hash-based integrity monitoring
* CSV/JSON output
* Configurable severity levels
* Integration with centralized logging
* Additional Linux security checks
* Automated scheduled scans

---

## Project Status

**Status: Functional prototype / portfolio project**

The current implementation successfully performs permission auditing, package attribution, logging, baseline comparison, and change detection in the tested Kali Linux environment.
