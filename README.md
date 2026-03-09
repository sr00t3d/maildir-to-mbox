# Maildir to MBOX Converter

[BR](README-ptbr.md)

![License](https://img.shields.io/github/license/sr00t3d/maildir-to-mbox) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg) ![Compatibility](https://img.shields.io/badge/compatible-Dovecot%20%7C%20Thunderbird-blue)

<img width="700" src="maildir-to-mbox-cover.webp" />

Professional script designed to automate the conversion of **Maildir (Dovecot)** email boxes to the **MBOX** format, natively compatible with **Mozilla Thunderbird**, preserving 100% of the folder hierarchy.

---

## Key Features

Unlike simple conversion scripts, this migrator was built for real-world SysAdmin scenarios:

- **Intelligent Detection**: Automatically locates hidden subfolders (e.g., `.Sent`, `.Archive`, `.Work.2023`).
- **Hierarchy Preservation**: Translates Dovecot’s dot-separated directory structure into Thunderbird’s subfolder format.
- **Operational Safety**:
  - Pre-execution disk space verification.
  - Custom CPU load profiles (e.g., `Nice 19`) to avoid impacting production servers.
  - 5-second emergency cancellation countdown.
- **Automated Collection**: Generates a random directory and a temporary public link for easy backup downloading.

---

## Installation

### Hosted mode

1. **Download the file to the server:**

```bash
curl -O https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh
```

2. **Give execution permission:**

```bash
chmod +x maildir-mbox.sh
```

3. **Execute the script:**

```bash
./maildir-mbox.sh
```

### Direct mode

```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh')
```

### 3. Follow the On-Screen Instructions

The script will prompt for:

1. CPU usage profile (Low impact vs. Maximum performance).
2. Confirmation of the destination directory.

---

## Output Structure

The script organizes messy Maildir files into a clean structure:
- `INBOX.mbox`
- `Sent.mbox`
- `Drafts.mbox`
- `Subfolder.sbd/` (Preserved hierarchy)

---

## Legal Notice

> [!WARNING]
> This software is provided "as is". Always make sure to test first in a development environment. The author is not responsible for any misuse, legal consequences, or data impact caused by this tool.

---

## Requirements

- **OS**: Linux (Debian, Ubuntu, CentOS, RHEL).
- **Dependencies**: `bash`, `curl`, `python3` (for the internal conversion engine).
- **Permissions**: Read access to the source Maildir and write access to the destination.

## Detailed Tutorial

For a complete step-by-step guide, check out my full article:

👉 [**How to migrate Dovecot to Thunderbird using Maildir-to-MBOX**](https://perciocastelo.com.br/blog/how-to-migrate-dovecot-to-thunderbird-using-maildir-to-mbox.html)

## License

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for details.