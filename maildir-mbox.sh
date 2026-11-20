#!/usr/bin/env bash
# +============================================================================+
# | maildir-mbox.sh                                                            |
# | Maildir to MBOX Converter v2.1.0                                           |
# | Converts Dovecot/cPanel Maildir structures into native MBOX archives       |
# | (Thunderbird-compatible) with folder hierarchy preservation, nice CPU      |
# | throttling, dry-run simulation, and table/JSON/CSV reporting.              |
# |                                                                            |
# | Author:  Percio Castelo                                                    |
# | Contact: percio@evolya.com.br | contato@perciocastelo.com.br               |
# | Web:     https://perciocastelo.com.br                                      |
# | Repo:    https://github.com/sr00t3d/maildir-to-mbox                        |
# |                                                                            |
# | Copyright 2024-2026 Percio Castelo                                         |
# | SPDX-License-Identifier: Apache-2.0                                        |
# +============================================================================+

set -uo pipefail

readonly VERSION="2.1.0"
readonly SCRIPT_NAME="$(basename "$0")"

# ---- Defaults ---------------------------------------------------------------
SOURCE_DIR="."
DEST_PATH=""
PROFILE="slow"
NO_COMPRESS=0
DRY_RUN=0
OUTPUT_FORMAT="table"
QUIET=0
NO_COLOR=0

TMP_DIR=""
cleanup() {
    if [[ -n "${TMP_DIR:-}" && -d "$TMP_DIR" ]]; then
        rm -rf "$TMP_DIR"
    fi
}
trap cleanup EXIT INT TERM

# ---- Color helpers ----------------------------------------------------------
init_colors() {
    if [[ "$NO_COLOR" -eq 1 || ! -t 1 ]]; then
        C_RESET="" C_BOLD="" C_GREEN="" C_YELLOW="" C_RED="" C_CYAN=""
    else
        C_RESET=$'\033[0m'
        C_BOLD=$'\033[1m'
        C_GREEN=$'\033[32m'
        C_YELLOW=$'\033[33m'
        C_RED=$'\033[31m'
        C_CYAN=$'\033[36m'
    fi
}

# ---- Help & Version ---------------------------------------------------------
show_version() {
    echo "Maildir to MBOX Converter v${VERSION}"
}

show_help() {
    cat <<EOF
Maildir to MBOX Converter v${VERSION}
Converts a Dovecot/cPanel Maildir mailbox into Thunderbird-compatible MBOX files.

Usage: ${SCRIPT_NAME} [OPTIONS]

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

Examples:
  ${SCRIPT_NAME} -s /home/user/mail/example.com/contato --dry-run
  ${SCRIPT_NAME} -s /home/user/mail/example.com/contato -d /root/backups/contato.tar.gz
  ${SCRIPT_NAME} -s /home/user/mail/example.com/contato -p fast -o json
  ${SCRIPT_NAME} -s /home/user/mail/example.com/contato --no-compress -d /tmp/mbox_out -o csv
EOF
}

# ---- Argument Parser --------------------------------------------------------
while [[ $# -gt 0 ]]; do
    case "$1" in
        -s|--source)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a directory argument." >&2; exit 1; }
            SOURCE_DIR="$2"; shift 2 ;;
        -d|--dest)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires a path argument." >&2; exit 1; }
            DEST_PATH="$2"; shift 2 ;;
        -p|--profile)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires 'slow' or 'fast'." >&2; exit 1; }
            PROFILE="$2"; shift 2 ;;
        --no-compress)
            NO_COMPRESS=1; shift ;;
        --dry-run)
            DRY_RUN=1; shift ;;
        -o|--output)
            [[ $# -lt 2 ]] && { echo "ERROR: $1 requires table, json, or csv." >&2; exit 1; }
            OUTPUT_FORMAT="$2"; shift 2 ;;
        -q|--quiet)
            QUIET=1; shift ;;
        --no-color)
            NO_COLOR=1; shift ;;
        -V|--version)
            show_version; exit 0 ;;
        -h|--help)
            show_help; exit 0 ;;
        *)
            echo "ERROR: Unknown option: $1 (run with -h for usage)" >&2
            exit 1 ;;
    esac
done

init_colors

# ---- Validations ------------------------------------------------------------
case "$PROFILE" in
    slow) NICE_VAL=19 ;;
    fast) NICE_VAL=0 ;;
    *)
        echo "${C_RED}ERROR: Invalid profile '${PROFILE}'. Expected 'slow' or 'fast'.${C_RESET}" >&2
        exit 1 ;;
esac

case "$OUTPUT_FORMAT" in
    table|json|csv) ;;
    *)
        echo "${C_RED}ERROR: Invalid output format '${OUTPUT_FORMAT}'. Expected table, json, or csv.${C_RESET}" >&2
        exit 1 ;;
esac

if ! command -v python3 >/dev/null 2>&1; then
    echo "${C_RED}ERROR: python3 is required for RFC-compliant Maildir-to-MBOX conversion.${C_RESET}" >&2
    exit 1
fi

if [[ ! -d "$SOURCE_DIR" ]]; then
    echo "${C_RED}ERROR: Source directory does not exist: ${SOURCE_DIR}${C_RESET}" >&2
    exit 1
fi

SOURCE_ABS="$(cd "$SOURCE_DIR" && pwd)"

if [[ ! -d "${SOURCE_ABS}/cur" && ! -d "${SOURCE_ABS}/new" ]]; then
    echo "${C_RED}ERROR: '${SOURCE_ABS}' is not a valid Maildir root (missing cur/ and new/).${C_RESET}" >&2
    exit 1
fi

# Infer account name from standard /.../domain.com/user layout
USER_NAME="$(basename "$SOURCE_ABS")"
DOMAIN_NAME="$(basename "$(dirname "$SOURCE_ABS")")"
ACCOUNT_LABEL="${USER_NAME}@${DOMAIN_NAME}"
TIMESTAMP_ISO="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
DATE_TAG="$(date +%Y%m%d_%H%M%S)"

if [[ -z "$DEST_PATH" ]]; then
    if [[ "$NO_COMPRESS" -eq 1 ]]; then
        DEST_PATH="$(pwd)/Maildir_MBOX_${USER_NAME}_${DATE_TAG}"
    else
        DEST_PATH="$(pwd)/Maildir_MBOX_${USER_NAME}_${DATE_TAG}.tar.gz"
    fi
fi

# ---- Folder Discovery -------------------------------------------------------
mapfile -t FOLDERS < <(
    cd "$SOURCE_ABS" && \
    find . -maxdepth 5 -type d ! -name "cur" ! -name "new" ! -name "tmp" | sort
)

# Arrays to hold per-folder stats
declare -a R_SRC=()
declare -a R_MBOX=()
declare -a R_FOUND=()
declare -a R_CONVERTED=()
declare -a R_FAILED=()
declare -a R_STATUS=()

TOTAL_FOUND=0
TOTAL_CONVERTED=0
TOTAL_FAILED=0

if [[ "$DRY_RUN" -eq 0 ]]; then
    if [[ "$NO_COMPRESS" -eq 1 ]]; then
        mkdir -p "$DEST_PATH"
        chmod 700 "$DEST_PATH"
        WORK_DIR="$DEST_PATH"
    else
        TMP_DIR="$(mktemp -d /tmp/maildir_mbox.XXXXXX)"
        chmod 700 "$TMP_DIR"
        WORK_DIR="$TMP_DIR"
    fi
else
    WORK_DIR=""
fi

# ---- Conversion Loop --------------------------------------------------------
for rel_folder in "${FOLDERS[@]}"; do
    if [[ "$rel_folder" == "." ]]; then
        dest_name="INBOX"
        full_src="$SOURCE_ABS"
    else
        dest_name="$(printf '%s' "$rel_folder" | sed 's/^\.\///;s/^\.//;s/\//-/g;s/\./-/g')"
        full_src="${SOURCE_ABS}/${rel_folder#./}"
    fi

    # Count messages inside cur/ and new/ of this specific Maildir folder
    msg_count=0
    if [[ -d "${full_src}/cur" ]]; then
        c_cur="$(find "${full_src}/cur" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
        msg_count=$((msg_count + c_cur))
    fi
    if [[ -d "${full_src}/new" ]]; then
        c_new="$(find "${full_src}/new" -maxdepth 1 -type f 2>/dev/null | wc -l | tr -d ' ')"
        msg_count=$((msg_count + c_new))
    fi

    TOTAL_FOUND=$((TOTAL_FOUND + msg_count))

    if [[ "$DRY_RUN" -eq 1 ]]; then
        R_SRC+=("$rel_folder")
        R_MBOX+=("$dest_name")
        R_FOUND+=("$msg_count")
        R_CONVERTED+=(0)
        R_FAILED+=(0)
        R_STATUS+=("WOULD_CONVERT")
        continue
    fi

    dest_file="${WORK_DIR}/${dest_name}"
    touch "$dest_file"
    chmod 600 "$dest_file"

    converted=0
    failed=0
    if [[ "$msg_count" -gt 0 ]]; then
        py_out="$(nice -n "$NICE_VAL" python3 - "$full_src" "$dest_file" <<'PYEOF'
import mailbox
import sys

src_dir, dst_mbox = sys.argv[1], sys.argv[2]
converted = 0
failed = 0
try:
    md = mailbox.Maildir(src_dir, create=False)
    mb = mailbox.mbox(dst_mbox)
    mb.lock()
    try:
        for key in md.iterkeys():
            try:
                mb.add(md[key])
                converted += 1
            except Exception:
                failed += 1
        mb.flush()
    finally:
        mb.unlock()
        mb.close()
except Exception:
    failed += 1
print(f"{converted} {failed}")
PYEOF
        )"
        read -r converted failed <<< "$py_out"
    fi

    TOTAL_CONVERTED=$((TOTAL_CONVERTED + converted))
    TOTAL_FAILED=$((TOTAL_FAILED + failed))

    folder_status="CONVERTED"
    if [[ "$msg_count" -eq 0 ]]; then
        folder_status="EMPTY"
    elif [[ "$failed" -gt 0 ]]; then
        folder_status="PARTIAL"
    fi

    R_SRC+=("$rel_folder")
    R_MBOX+=("$dest_name")
    R_FOUND+=("$msg_count")
    R_CONVERTED+=("$converted")
    R_FAILED+=("$failed")
    R_STATUS+=("$folder_status")
done

# ---- Packaging --------------------------------------------------------------
ARCHIVE_SIZE=0
OVERALL_STATUS="SUCCESS"
if [[ "$DRY_RUN" -eq 1 ]]; then
    OVERALL_STATUS="DRY_RUN"
elif [[ "$NO_COMPRESS" -eq 0 ]]; then
    mkdir -p "$(dirname "$DEST_PATH")"
    tar -czf "$DEST_PATH" -C "$WORK_DIR" .
    chmod 600 "$DEST_PATH"
    ARCHIVE_SIZE="$(stat -c%s "$DEST_PATH" 2>/dev/null || wc -c < "$DEST_PATH" | tr -d ' ')"
fi

if [[ "$TOTAL_FAILED" -gt 0 && "$DRY_RUN" -eq 0 ]]; then
    OVERALL_STATUS="PARTIAL"
fi

# ---- Reporting --------------------------------------------------------------
json_escape() {
    printf '%s' "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if [[ "$QUIET" -eq 0 ]]; then
    if [[ "$OUTPUT_FORMAT" == "json" ]]; then
        printf '{\n'
        printf '  "version": "%s",\n' "$VERSION"
        printf '  "status": "%s",\n' "$OVERALL_STATUS"
        printf '  "account": "%s",\n' "$(json_escape "$ACCOUNT_LABEL")"
        printf '  "source_dir": "%s",\n' "$(json_escape "$SOURCE_ABS")"
        printf '  "destination": "%s",\n' "$(json_escape "$DEST_PATH")"
        printf '  "compressed": %s,\n' "$([[ "$NO_COMPRESS" -eq 0 ]] && echo true || echo false)"
        printf '  "archive_bytes": %s,\n' "$ARCHIVE_SIZE"
        printf '  "profile": "%s",\n' "$PROFILE"
        printf '  "nice": %s,\n' "$NICE_VAL"
        printf '  "dry_run": %s,\n' "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)"
        printf '  "folders_count": %d,\n' "${#R_SRC[@]}"
        printf '  "total_messages_found": %d,\n' "$TOTAL_FOUND"
        printf '  "total_messages_converted": %d,\n' "$TOTAL_CONVERTED"
        printf '  "total_messages_failed": %d,\n' "$TOTAL_FAILED"
        printf '  "timestamp": "%s",\n' "$TIMESTAMP_ISO"
        printf '  "folders": [\n'
        for i in "${!R_SRC[@]}"; do
            comma=","
            [[ "$i" -eq $((${#R_SRC[@]} - 1)) ]] && comma=""
            printf '    {"source": "%s", "mbox": "%s", "found": %d, "converted": %d, "failed": %d, "status": "%s"}%s\n' \
                "$(json_escape "${R_SRC[$i]}")" \
                "$(json_escape "${R_MBOX[$i]}")" \
                "${R_FOUND[$i]}" \
                "${R_CONVERTED[$i]}" \
                "${R_FAILED[$i]}" \
                "${R_STATUS[$i]}" \
                "$comma"
        done
        printf '  ]\n'
        printf '}\n'

    elif [[ "$OUTPUT_FORMAT" == "csv" ]]; then
        echo "timestamp,account,profile,dry_run,source_folder,mbox_name,found,converted,failed,status"
        for i in "${!R_SRC[@]}"; do
            printf '%s,"%s",%s,%s,"%s","%s",%d,%d,%d,%s\n' \
                "$TIMESTAMP_ISO" \
                "$ACCOUNT_LABEL" \
                "$PROFILE" \
                "$([[ "$DRY_RUN" -eq 1 ]] && echo true || echo false)" \
                "${R_SRC[$i]}" \
                "${R_MBOX[$i]}" \
                "${R_FOUND[$i]}" \
                "${R_CONVERTED[$i]}" \
                "${R_FAILED[$i]}" \
                "${R_STATUS[$i]}"
        done

    else
        BORDER="+----------------------+----------------------+-------+-----------+--------+---------------+"
        echo ""
        echo "${C_BOLD}Maildir to MBOX Converter v${VERSION}${C_RESET}"
        echo "Account    : ${ACCOUNT_LABEL}"
        echo "Source     : ${SOURCE_ABS}"
        echo "Destination: ${DEST_PATH}"
        echo "Profile    : ${PROFILE} (nice ${NICE_VAL})"
        echo "Dry-Run    : $([[ "$DRY_RUN" -eq 1 ]] && echo yes || echo no)"
        echo "Status     : ${OVERALL_STATUS}"
        echo "Timestamp  : ${TIMESTAMP_ISO}"
        echo ""
        echo "$BORDER"
        printf "| %-20s | %-20s | %5s | %9s | %6s | %-13s |\n" \
            "Source Folder" "MBOX Name" "Found" "Converted" "Failed" "Status"
        echo "$BORDER"
        for i in "${!R_SRC[@]}"; do
            printf "| %-20s | %-20s | %5d | %9d | %6d | %-13s |\n" \
                "${R_SRC[$i]}" "${R_MBOX[$i]}" "${R_FOUND[$i]}" "${R_CONVERTED[$i]}" "${R_FAILED[$i]}" "${R_STATUS[$i]}"
        done
        echo "$BORDER"
        if [[ "$DRY_RUN" -eq 0 && "$NO_COMPRESS" -eq 0 ]]; then
            echo "Summary    : ${#R_SRC[@]} folders | ${TOTAL_CONVERTED}/${TOTAL_FOUND} messages converted (${TOTAL_FAILED} failed) | archive ${ARCHIVE_SIZE} bytes (chmod 600)"
        else
            echo "Summary    : ${#R_SRC[@]} folders | ${TOTAL_CONVERTED}/${TOTAL_FOUND} messages converted (${TOTAL_FAILED} failed)"
        fi
        echo ""
    fi
fi

exit 0
