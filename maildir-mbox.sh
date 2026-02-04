#!/bin/bash

# ==============================================================================
# Autor: Percio Andrade - percio@evolya.com.br
# Descrição: Converte estruturas Maildir (Dovecot) para o formato nativo do 
#            Thunderbird (MBOX sem extensão), incluindo pastas vazias.
# Versão: 1.1.1 (Fev/2026)
# Utilização: curl -sSL https://raw.githubusercontent.com/... | bash
# ==============================================================================

exec 3<&0
exec 0< /dev/tty

# --- 1. Verificação de Ambiente ---
if [ ! -d "cur" ] && [ ! -d ".Sent" ]; then
    echo "❌ Erro: Execute este script dentro da pasta raiz do e-mail."
    exit 1
fi

USER_NAME=$(basename $(pwd))
DOMAIN_NAME=$(basename $(dirname $(pwd)))
EMAIL_ADDR="${USER_NAME}@${DOMAIN_NAME}"
EXPORT_NAME="Thunderbird_Full_Backup_${USER_NAME}"
TMP_DIR="/tmp/conv_thunderbird_${USER_NAME}_$RANDOM"

mkdir -p "$TMP_DIR"

# --- 2. Levantamento de Dados ---
# MUDANÇA: Agora buscamos todos os diretórios, exceto os de sistema do Maildir (cur/new/tmp)
# Isso garante que pastas vazias como '.Meus' sejam detectadas.
MAP_FOLDERS=$(find . -maxdepth 4 -type d ! -name "cur" ! -name "new" ! -name "tmp" | sort)
NUM_FOLDERS=$(echo "$MAP_FOLDERS" | wc -l)
TOTAL_FILES=$(find . -type f \( -path "*/cur/*" -o -path "*/new/*" \) | wc -l)

echo "----------------------------------------------------"
echo "📧 Conta detectada: $EMAIL_ADDR"
echo "📂 Estruturas de pastas: $NUM_FOLDERS"
echo "✉️  Total de e-mails: $TOTAL_FILES"
echo "----------------------------------------------------"

# --- 3. Perfil e Countdown ---
read -p "Escolha o perfil [A] Rápido [B] Lento: " OPTION
[[ "$OPTION" =~ ^[Bb]$ ]] && NICE_VAL=19 || NICE_VAL=0

echo -e "\n⚠️  Iniciando em 5 segundos... [CTRL+C] para cancelar."
for i in {5..1}; do echo -ne "Aguarde... $i \r"; sleep 1; done
echo -e "\n🚀 Processando...\n"

# --- 4. Conversão e Criação de Estrutura ---
CURRENT_F=0
while read -r folder; do
    ((CURRENT_F++))
    
    if [ "$folder" == "." ]; then
        DEST_NAME="INBOX_Principal"
    else
        # Limpa o nome para o padrão Thunderbird
        DEST_NAME=$(echo "$folder" | sed 's/^\.\///;s/^\.//;s/\//-/g;s/\./-/g')
    fi

    # O SEGREDO: Criamos o arquivo (mesmo que vazio) para a pasta aparecer no Thunderbird
    touch "$TMP_DIR/$DEST_NAME"

    # Se a pasta tiver e-mails (tiver subpasta cur), o Python popula o arquivo
    if [ -d "$folder/cur" ]; then
        nice -n $NICE_VAL python3 -c "import mailbox; 
try:
    md = mailbox.Maildir('$folder'); 
    mb = mailbox.mbox('$TMP_DIR/$DEST_NAME'); 
    mb.lock(); 
    [mb.add(m) for m in md]; 
    mb.flush(); 
    mb.close()
except:
    pass" 2>/dev/null
    fi
    
    PERCENT=$(( (CURRENT_F * 100) / NUM_FOLDERS ))
    printf "\rProgresso: [%-40s] %d%% (%d/%d)" $(printf "#%.0s" $(seq 1 $((PERCENT/4)))) $PERCENT $CURRENT_F $NUM_FOLDERS
done <<< "$MAP_FOLDERS"

# --- 5. Compactação e Link ---
echo -e "\n\n📦 Finalizando pacote..."
tar -czf "${EXPORT_NAME}.tar.gz" -C "$TMP_DIR" .
rm -rf "$TMP_DIR"

# Detecção de WEB_ROOT
WEB_ROOT=""
for dir in "/var/www/html" "/home/$USER_NAME/public_html" "/var/www/$DOMAIN_NAME/public_html"; do
    [ -d "$dir" ] && WEB_ROOT="$dir" && break
done

if [ ! -z "$WEB_ROOT" ]; then
    RAND_DIR="backup_$(openssl rand -hex 3)"
    mkdir -p "$WEB_ROOT/$RAND_DIR"
    cp "${EXPORT_NAME}.tar.gz" "$WEB_ROOT/$RAND_DIR/"
    chmod 644 "$WEB_ROOT/$RAND_DIR/${EXPORT_NAME}.tar.gz"
    SERVER_IP=$(curl -s https://ifconfig.me || hostname -I | awk '{print $1}')
    echo "----------------------------------------------------"
    echo "🌐 Download: http://$SERVER_IP/$RAND_DIR/${EXPORT_NAME}.tar.gz"
fi
echo "✅ Processo concluído!"
