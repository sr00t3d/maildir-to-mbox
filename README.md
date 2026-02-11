# Maildir to MBOX Converter 📧

Readme: [Português](README.pt-br.md)

![License](https://img.shields.io/github/license/sr00t3d/maildir-to-mbox)
![Shell Script](https://img.shields.io/badge/language-Bash-green.svg)
![Compatibility](https://img.shields.io/badge/compatible-Dovecot%20%7C%20Thunderbird-blue)

Professional script designed to automate the conversion of **Maildir (Dovecot)** email boxes to the **MBOX** format, natively compatible with **Mozilla Thunderbird**, preserving 100% of the folder hierarchy.

---

## ✨ Key Features

Unlike simple conversion scripts, this migrator was built for real-world SysAdmin scenarios:

- **Intelligent Detection**: Automatically locates hidden subfolders (e.g., `.Sent`, `.Archive`, `.Work.2023`).
- **Hierarchy Preservation**: Translates Dovecot’s dot-separated directory structure into Thunderbird’s subfolder format.
- **Operational Safety**:
  - Pre-execution disk space verification.
  - Custom CPU load profiles (e.g., `Nice 19`) to avoid impacting production servers.
  - 5-second emergency cancellation countdown.
- **Automated Collection**: Generates a random directory and a temporary public link for easy backup downloading.

---

## 🚀 Quick Start

No need to clone the repository. You can run the migrator directly on the server where the emails are located.

### 1. Access the user's mail directory
Navigate to the root of the email account (where `cur`, `new`, and `tmp` folders are located):
```bash
cd /home/user/mail/domain.com/account/ (or equivalent)
```

### 2. Run the Migrator
```bash
bash <(curl -sSL https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh)
```

### 3. Follow the On-Screen Instructions
The script will prompt for:
1. CPU usage profile (Low impact vs. Maximum performance).
2. Confirmation of the destination directory.

---

## 📁 Output Structure

The script organizes messy Maildir files into a clean structure:
- `INBOX.mbox`
- `Sent.mbox`
- `Drafts.mbox`
- `Subfolder.sbd/` (Preserved hierarchy)

---

## ⚠️ Disclaimer

> [!WARNING]
> This software is provided "as-is". While extensively tested in Dovecot environments, **always perform a full backup** of your Maildir directories before running any conversion script. The author is not responsible for any data loss.

---

## 🛠️ Requirements

- **OS**: Linux (Debian, Ubuntu, CentOS, RHEL).
- **Dependencies**: `bash`, `curl`, `python3` (for the internal conversion engine).
- **Permissions**: Read access to the source Maildir and write access to the destination.

## 📚 Detailed Tutorial

For a complete step-by-step guide on how to import the generated files into Thunderbird and troubleshoot common migration issues, check out my full article:

👉 [**How to migrate Dovecot to Thunderbird using Maildir-to-MBOX**](https://perciocastelo.com.br/blog/how-to-migrate-dovecot-to-thunderbird-using-maildir-to-mbox.html)

## License 📄

This project is licensed under the **GNU General Public License v3.0**. See the [LICENSE](LICENSE) file for details.
