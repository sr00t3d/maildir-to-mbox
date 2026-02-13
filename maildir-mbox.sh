#!/bin/bash
################################################################################
#                                                                              #
#   PROJECT: Maildir to Thunderbird Converter                                  #
#   VERSION: 2.0.0                                                             #
#                                                                              #
#   AUTHOR:  Percio Andrade                                                    #
#   CONTACT: percio@evolya.com.br                                              #
#   WEB:     https://perciocastelo.com.br | contato@perciocastelo.com.br       #
#                                                                              #
#   INFO:                                                                      #
#   Converts Dovecot Maildir structure to Thunderbird native MBOX format.      #
#   Handles empty folders and creates a web-accessible backup link.            #
#                                                                              #
################################################################################

# --- CONFIGURATION ---
TMP_DIR="/tmp/conv_thunderbird_$(date +%s)_$RANDOM"
# ---------------------

# Detect System Language
SYSTEM_LANG="${LANG:0:2}"

if [[ "$SYSTEM_LANG" == "pt" ]]; then
    # Portuguese Strings
    MSG_ERR_DIR="❌ Erro: Execute este script dentro da pasta raiz do e-mail (onde estão .Sent, cur, etc)."
    MSG_DETECTED="📧 Conta detectada:"
    MSG_STRUCT="📂 Estruturas de pastas:"
    MSG_TOTAL="✉️  Total de e-mails:"
    MSG_PROFILE="Escolha o perfil de CPU:"
    MSG_OPT_FAST="[A] Rápido (Consome mais CPU)"
    MSG_OPT_SLOW="[B] Lento (Nice mode - Seguro para produção)"
    MSG_WAIT="⚠️  Iniciando em 5 segundos... [CTRL+C] para cancelar."
    MSG_PROC="🚀 Processando..."
    MSG_PROG="Progresso"
    MSG_PACK="📦 Compactando arquivos..."
    MSG_WEB_COPY="🌐 Copiando para diretório público..."
    MSG_LINK="✅ Download disponível:"
    MSG_DONE="✅ Processo concluído! Arquivo salvo em:"
    MSG_PERM_ERR="⚠️  Diretório web encontrado, mas sem permissão de escrita:"
else
    # English Strings (Default)
    MSG_ERR_DIR="❌ Error: Run this script inside the email root folder (containing .Sent, cur, etc)."
    MSG_DETECTED="📧 Account detected:"
    MSG_STRUCT="📂 Folder structure:"
    MSG_TOTAL="✉️  Total emails:"
    MSG_PROFILE="Choose CPU profile:"
    MSG_OPT_FAST="[A] Fast (High CPU usage)"
    MSG_OPT_SLOW="[B] Slow (Nice mode - Safe for production)"
    MSG_WAIT="⚠️  Starting in 5 seconds... [CTRL+C] to cancel."
    MSG_PROC="🚀 Processing..."
    MSG_PROG="Progress"
    MSG_PACK="📦 Compressing files..."
    MSG_WEB_COPY="🌐 Copying to public directory..."
    MSG_LINK="✅ Download available:"
    MSG_DONE="✅ Process completed! File saved at:"
    MSG_PERM_ERR="⚠️  Web directory found, but not writable:"
fi

# --- 1. Environment Check ---
if [ ! -d "cur" ] && [ ! -d "new" ]; then
    echo "$MSG_ERR_DIR"
    exit 1
fi

# Get User/Domain from path structure
# Assumes standard path: /.../domain.com/user/mail
USER_NAME=$(basename "$(pwd)")
DOMAIN_NAME=$(basename "$(dirname "$(pwd)")")
EMAIL_ADDR="${USER_NAME}@${DOMAIN_NAME}"
EXPORT_NAME="Thunderbird_Backup_${USER_NAME}_$(date +%Y%m%d)"

mkdir -p "$TMP_DIR"

# --- 2. Data Gathering ---
# Find all directories that are NOT system folders (cur/new/tmp)
# This captures folders like ".Sent", ".Trash", ".MyFolder"
MAP_FOLDERS=$(find . -maxdepth 5 -type d ! -name "cur" ! -name "new" ! -name "tmp" | sort)
NUM_FOLDERS=$(echo "$MAP_FOLDERS" | wc -l)
# Count actual email files
TOTAL_FILES=$(find . -type f \( -path "*/cur/*" -o -path "*/new/*" \) | wc -l)

echo "----------------------------------------------------"
echo "$MSG_DETECTED $EMAIL_ADDR"
echo "$MSG_STRUCT $NUM_FOLDERS"
echo "$MSG_TOTAL $TOTAL_FILES"
echo "----------------------------------------------------"

# --- 3. Profile Selection ---
echo "$MSG_PROFILE"
echo "$MSG_OPT_FAST"
echo -n "$MSG_OPT_SLOW: "

# Read from TTY to allow piping via curl
if [ -t 0 ]; then
    read -r OPTION
else
    read -r OPTION < /dev/tty
fi

# Set niceness
if [[ "$OPTION" =~ ^[Bb]$ ]]; then
    NICE_VAL=19
else
    NICE_VAL=0
fi

echo -e "\n$MSG_WAIT"
for i in {5..1}; do 
    echo -ne " $i... \r"
    sleep 1
done
echo -e "\n$MSG_PROC\n"

# --- 4. Conversion Loop ---
CURRENT_F=0

# Use process substitution to avoid subshell issues
while read -r folder; do
    ((CURRENT_F++))
    
    # Root folder handling
    if [ "$folder" == "." ]; then
        DEST_NAME="INBOX"
    else
        # Sanitize: Remove leading ./ or ., replace / and . with -
        # Example: .Sent -> Sent | .Custom.Folder -> Custom-Folder
        DEST_NAME=$(echo "$folder" | sed 's/^\.\///;s/^\.//;s/\//-/g;s/\./-/g')
    fi

    # 1. Create the file (Touch)
    # Essential for Thunderbird to recognize empty folders
    touch "$TMP_DIR/$DEST_NAME"

    # 2. Convert Emails if 'cur' exists
    if [ -d "$folder/cur" ]; then
        # Python script: Updated to use a loop instead of list comprehension for memory efficiency
        nice -n $NICE_VAL python3 -c "
import mailbox
import sys
try:
    md = mailbox.Maildir('$folder')
    mb = mailbox.mbox('$TMP_DIR/$DEST_NAME')
    mb.lock()
    for key in md.iterkeys():
        try:
            mb.add(md[key])
        except:
            continue
    mb.flush()
    mb.close()
except Exception:
    pass
" 2>/dev/null
    fi
    
    # 3. Progress Bar
    if [ "$NUM_FOLDERS" -gt 0 ]; then
        PERCENT=$(( (CURRENT_F * 100) / NUM_FOLDERS ))
    else
        PERCENT=100
    fi
    
    # Simplified visual bar
    BAR_LEN=$((PERCENT / 2))
    printf "\r$MSG_PROG: [%-50s] %d%%" "$(printf "%0.s#" $(seq 1 $BAR_LEN))" "$PERCENT"

done <<< "$MAP_FOLDERS"

# --- 5. Packaging & Distribution ---
echo -e "\n\n$MSG_PACK"
TAR_FILE="${EXPORT_NAME}.tar.gz"
tar -czf "$TAR_FILE" -C "$TMP_DIR" .

# Cleanup temp
rm -rf "$TMP_DIR"

# Web Root Detection & Copy
WEB_ROOT=""
# List of common web roots to check
CANDIDATES=(
    "/home/$USER_NAME/public_html"
    "/var/www/$DOMAIN_NAME/public_html"
    "/var/www/html"
)

for dir in "${CANDIDATES[@]}"; do
    if [ -d "$dir" ]; then
        # CRITICAL: Check if we have write permission
        if [ -w "$dir" ]; then
            WEB_ROOT="$dir"
            break
        fi
    fi
done

if [ -n "$WEB_ROOT" ]; then
    echo "$MSG_WEB_COPY"
    RAND_DIR="bkp_$(openssl rand -hex 4)"
    mkdir -p "$WEB_ROOT/$RAND_DIR"
    
    cp "$TAR_FILE" "$WEB_ROOT/$RAND_DIR/"
    chmod 644 "$WEB_ROOT/$RAND_DIR/$TAR_FILE"
    
    # Try to determine IP
    SERVER_IP=$(curl -s --connect-timeout 2 https://ifconfig.me || hostname -I | awk '{print $1}')
    
    echo "----------------------------------------------------"
    echo "$MSG_LINK http://$SERVER_IP/$RAND_DIR/$TAR_FILE"
    echo "----------------------------------------------------"
    
    # Remove local file if copied successfully to web root
    rm -f "$TAR_FILE"
else
    if [ -d "/var/www/html" ] && [ ! -w "/var/www/html" ]; then
        echo "$MSG_PERM_ERR /var/www/html"
    fi
    echo "$MSG_DONE $(pwd)/$TAR_FILE"
fi
