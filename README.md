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

<img width="506" height="128" alt="image" src="https://github.com/user-attachments/assets/4d72fecd-e12c-407b-88d1-9da57c52805b" />

### 3. Selecione o perfil da CPU

<img width="395" height="32" alt="image" src="https://github.com/user-attachments/assets/fb7cd5cc-7fe0-4402-a066-6506d66a9443" />

### 4. Aguarde a conversão
<img width="668" height="170" alt="image" src="https://github.com/user-attachments/assets/7fcb9a1c-8764-401a-ad22-a644f2f94993" />

### 5. Localize o arquivo gerado
<img width="444" height="300" alt="image" src="https://github.com/user-attachments/assets/73efbf70-9aff-48a1-bf3f-7497da2ec1d7" />


### 📂 Como Restaurar no Thunderbird
Após o script gerar o link e você baixar o arquivo .tar.gz, siga estes passos:

Extraia o arquivo no seu computador local.

<img width="582" height="220" alt="image" src="https://github.com/user-attachments/assets/220efb10-7655-45ca-9f66-1d95490da50e" />

No Thunderbird, vá em Configurações da Conta > Pastas Locais (Local Folders).

<img width="294" height="129" alt="image" src="https://github.com/user-attachments/assets/4afc8264-a55a-4af0-b8c0-d26827bb997e" />

Verifique o caminho em Diretório Local.

<img width="784" height="111" alt="image" src="https://github.com/user-attachments/assets/60a08d97-71b6-4473-918a-11f940c6bfb0" />

Feche o Thunderbird.

Copie os arquivos extraídos (ex: INBOX_Principal, Sent, Meus-Trabalho) para dentro desta pasta no Windows/Linux/Mac.

<img width="1084" height="260" alt="image" src="https://github.com/user-attachments/assets/a71df04f-a31d-4c8c-9644-3d57d965e3c1" />

Abra o Thunderbird e as pastas e email aparecerão magicamente no menu lateral.

<img width="612" height="277" alt="image" src="https://github.com/user-attachments/assets/ce59d29c-3769-4fda-a146-22e27302cb84" />

Agora mova os emails para as contas existentes em seu aplicativo Thunderbird

### 📋 Requisitos do Servidor
- Linux (Debian, Ubuntu, CentOS, etc.)
- Python 3 instalado (nativo na maioria das distros)
- Permissão de escrita na pasta /tmp e no DocumentRoot do servidor web (opcional para link de download).

### 👤 Autor
- Percio Andrade: percio@evolya.com.br | perciocastelo@gmail.com
- Este software é fornecido "no estado em que se encontra", sem garantias de qualquer tipo. Sempre faça backup dos seus dados antes de realizar migrações.
