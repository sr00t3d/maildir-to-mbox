# Maildir to MBOX Converter

Readme: [PT-BR](README-ptbr.md)

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.1.0-green.svg)](https://github.com/sr00t3d/maildir-to-mbox/releases)
[![Shell](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)

<img width="700" src="maildir-to-mbox-cover.webp" alt="Maildir to MBOX Converter" />

**Maildir to MBOX Converter v2.1.0** is a Linux CLI tool that converts Dovecot/cPanel `Maildir` directory trees (including `cur/`, `new/`, and nested dot-folders such as `.Sent`, `.Drafts`, and `.Archive.2026`) into RFC-compliant `MBOX` files ready for Mozilla Thunderbird, Apple Mail, or archival migrations.

---

## Features

- **Full Folder Hierarchy Preservation**: converts root Maildir to `INBOX` and maps nested dot-folders (e.g., `.Archive.2026` -> `Archive-2026`), preserving empty folders as zero-byte MBOX files for Thunderbird compatibility
- **RFC-Compliant Conversion**: delegates message parsing and locking to Python 3's standard `mailbox.Maildir` and `mailbox.mbox` modules via safe `sys.argv` passing (no shell/code injection)
- **Both `cur/` and `new/` Included**: captures both read and unread messages automatically
- **Production CPU Throttling (`-p slow|fast`)**: defaults to `slow` (`nice 19`) to avoid I/O and CPU starvation on live cPanel/Dovecot servers
- **Secure Output Handling (`chmod 600`)**: stores the resulting `.tar.gz` archive (or unpacked directory via `--no-compress`) with owner-only permissions and never exposes private email backups in public webroots
- **Dry-Run Simulation (`--dry-run`)**: scans folders and counts messages without creating files
- **Multi-Format Reporting (`-o table|json|csv`)**: ASCII tables, JSON for pipelines, or CSV for migration audits

---

## Requirements

- Linux with Bash 4+
- `python3` (standard library `mailbox` module, zero third-party packages)
- `tar` and `find`

---

## Installation

```bash
curl -fsSLO https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh
chmod +x maildir-mbox.sh
```

---

## Usage

```bash
./maildir-mbox.sh [OPTIONS]

Options:
  -s, --source DIR        Path to Maildir root (must contain cur/ or new/) [default: .]
  -d, --dest PATH         Destination .tar.gz file (or directory when --no-compress)
  -p, --profile MODE      CPU priority: slow (nice 19, default) or fast (nice 0)
  --no-compress           Keep converted MBOX files in a directory instead of .tar.gz
  --dry-run               Scan Maildir and preview conversion plan without writing files
  -o, --output FORMAT     Output format: table (default), json, csv
  -q, --quiet             Suppress standard output (errors still go to stderr)
  --no-color              Disable ANSI colors
  -V, --version           Show version and exit
  -h, --help              Show this help and exit
```

### Examples

```bash
# Preview folder mapping and message counts without writing anything
./maildir-mbox.sh -s /home/user/mail/example.com/contato --dry-run

# Convert safely on a production server (default nice 19) into a chmod 600 archive
./maildir-mbox.sh -s /home/user/mail/example.com/contato -d /root/backups/contato.tar.gz

# Fast conversion with JSON output for automation pipelines
./maildir-mbox.sh -s /home/user/mail/example.com/contato -p fast -o json

# Export uncompressed MBOX files into a directory with CSV audit output
./maildir-mbox.sh -s /home/user/mail/example.com/contato --no-compress -d /root/mbox_out -o csv
```

---

## Real Output Example

Captured live on an AlmaLinux 8.10 cPanel/WHM server:

### Table output (default)

```text
$ ./maildir-mbox.sh -s /tmp/maildir-e2e/perciocastelo.com.br/contato -d /tmp/maildir-e2e/contato_backup.tar.gz -p slow --no-color

Maildir to MBOX Converter v2.1.0
Account    : contato@perciocastelo.com.br
Source     : /tmp/maildir-e2e/perciocastelo.com.br/contato
Destination: /tmp/maildir-e2e/contato_backup.tar.gz
Profile    : slow (nice 19)
Dry-Run    : no
Status     : SUCCESS
Timestamp  : 2026-11-20T05:31:15Z

+----------------------+----------------------+-------+-----------+--------+---------------+
| Source Folder        | MBOX Name            | Found | Converted | Failed | Status        |
+----------------------+----------------------+-------+-----------+--------+---------------+
| .                    | INBOX                |     2 |         2 |      0 | CONVERTED     |
| ./.Archive.2026      | Archive-2026         |     1 |         1 |      0 | CONVERTED     |
| ./.Drafts            | Drafts               |     0 |         0 |      0 | EMPTY         |
| ./.Sent              | Sent                 |     1 |         1 |      0 | CONVERTED     |
| ./.Trash             | Trash                |     0 |         0 |      0 | EMPTY         |
+----------------------+----------------------+-------+-----------+--------+---------------+
Summary    : 5 folders | 4/4 messages converted (0 failed) | archive 644 bytes (chmod 600)
```

### Dry-run simulation (`--dry-run`)

```text
$ ./maildir-mbox.sh -s /tmp/maildir-e2e/perciocastelo.com.br/contato --dry-run --no-color

Maildir to MBOX Converter v2.1.0
Account    : contato@perciocastelo.com.br
Source     : /tmp/maildir-e2e/perciocastelo.com.br/contato
Destination: /root/Maildir_MBOX_contato_20261120_023115.tar.gz
Profile    : slow (nice 19)
Dry-Run    : yes
Status     : DRY_RUN
Timestamp  : 2026-11-20T05:31:15Z

+----------------------+----------------------+-------+-----------+--------+---------------+
| Source Folder        | MBOX Name            | Found | Converted | Failed | Status        |
+----------------------+----------------------+-------+-----------+--------+---------------+
| .                    | INBOX                |     2 |         0 |      0 | WOULD_CONVERT |
| ./.Archive.2026      | Archive-2026         |     1 |         0 |      0 | WOULD_CONVERT |
| ./.Drafts            | Drafts               |     0 |         0 |      0 | WOULD_CONVERT |
| ./.Sent              | Sent                 |     1 |         0 |      0 | WOULD_CONVERT |
| ./.Trash             | Trash                |     0 |         0 |      0 | WOULD_CONVERT |
+----------------------+----------------------+-------+-----------+--------+---------------+
Summary    : 5 folders | 0/4 messages converted (0 failed)
```

### JSON output (`-o json`)

```json
{
  "version": "2.1.0",
  "status": "SUCCESS",
  "account": "contato@perciocastelo.com.br",
  "source_dir": "/tmp/maildir-e2e/perciocastelo.com.br/contato",
  "destination": "/tmp/maildir-e2e/contato_fast.tar.gz",
  "compressed": true,
  "archive_bytes": 644,
  "profile": "fast",
  "nice": 0,
  "dry_run": false,
  "folders_count": 5,
  "total_messages_found": 4,
  "total_messages_converted": 4,
  "total_messages_failed": 0,
  "timestamp": "2026-11-20T05:31:16Z",
  "folders": [
    {"source": ".", "mbox": "INBOX", "found": 2, "converted": 2, "failed": 0, "status": "CONVERTED"},
    {"source": "./.Archive.2026", "mbox": "Archive-2026", "found": 1, "converted": 1, "failed": 0, "status": "CONVERTED"},
    {"source": "./.Drafts", "mbox": "Drafts", "found": 0, "converted": 0, "failed": 0, "status": "EMPTY"},
    {"source": "./.Sent", "mbox": "Sent", "found": 1, "converted": 1, "failed": 0, "status": "CONVERTED"},
    {"source": "./.Trash", "mbox": "Trash", "found": 0, "converted": 0, "failed": 0, "status": "EMPTY"}
  ]
}
```

### CSV output (`--no-compress -o csv`)

```csv
timestamp,account,profile,dry_run,source_folder,mbox_name,found,converted,failed,status
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,".","INBOX",2,2,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Archive.2026","Archive-2026",1,1,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Drafts","Drafts",0,0,0,EMPTY
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Sent","Sent",1,1,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Trash","Trash",0,0,0,EMPTY
```

---

## License

Apache-2.0. See [LICENSE](LICENSE) for details.

## Author

[Percio Castelo](https://perciocastelo.com.br)
