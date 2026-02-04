# maildir-to-mbox
Convert maildir directory (dovecot) to mbox files

[![Bash Script](https://img.shields.io/badge/Language-Bash-green.svg)](https://www.gnu.org/software/bash/)
[![Python 3](https://img.shields.io/badge/Python-3.x-blue.svg)](https://www.python.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

Script profissional desenvolvido para automatizar a conversão de caixas de e-mail no formato **Maildir (Dovecot)** para o formato nativo do **Mozilla Thunderbird**, preservando 100% da hierarquia de pastas (mesmo pastas ocultas e vazias).

## 🛠️ O que o script faz?

- **Detecção Agressiva**: Localiza todas as subpastas (ex: `.Sent`, `.Archive`, `.Meus.Trabalhos`).
- **Preservação de Hierarquia**: Converte a estrutura de pontos do Dovecot para um formato legível pelo Thunderbird.
- **Segurança Operacional**: Verifica espaço em disco e permite escolher a carga de CPU (Nice 19 para servidores em produção).
- **Countdown de Segurança**: 5 segundos para cancelamento antes de iniciar.
- **Link de Download**: Gera automaticamente um link público com diretório aleatório para facilitar a coleta do backup.

---

## 🚀 Como utilizar (Quick Start)

Não é necessário baixar o script manualmente. Você pode executá-lo diretamente do GitHub no servidor onde os e-mails estão localizados.

### 1. Acesse a pasta raiz do e-mail do usuário
Geralmente localizada em `/home/usuario/mail/dominio.com.br/conta/`.

```bash
cd /caminho/para/o/maildir/do/usuario
```

### 2. Execute o Migrador
Execute o comando abaixo:
```bash
bash <(curl -sSL https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh)
```

### 3. Selecione o perfil da CPU


### 📂 Como Restaurar no Thunderbird
Após o script gerar o link e você baixar o arquivo .tar.gz, siga estes passos:

Extraia o arquivo no seu computador local.

No Thunderbird, vá em Configurações da Conta > Pastas Locais (Local Folders).

Verifique o caminho em Diretório Local.

Feche o Thunderbird.

Copie os arquivos extraídos (ex: INBOX_Principal, Sent, Meus-Trabalho) para dentro desta pasta no Windows/Linux/Mac.

Abra o Thunderbird e as pastas aparecerão magicamente no menu lateral.

### 📋 Requisitos do Servidor
- Linux (Debian, Ubuntu, CentOS, etc.)
- Python 3 instalado (nativo na maioria das distros)
- Permissão de escrita na pasta /tmp e no DocumentRoot do servidor web (opcional para link de download).

### 👤 Autor
- Percio Andrade: percio@evolya.com.br | perciocastelo@gmail.com
- Este software é fornecido "no estado em que se encontra", sem garantias de qualquer tipo. Sempre faça backup dos seus dados antes de realizar migrações.
