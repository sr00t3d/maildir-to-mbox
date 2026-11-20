# Maildir to MBOX Converter

Readme: [EN](README.md)

[![License](https://img.shields.io/badge/license-Apache--2.0-blue.svg)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.1.0-green.svg)](https://github.com/sr00t3d/maildir-to-mbox/releases)
[![Shell](https://img.shields.io/badge/bash-4.0+-blue.svg)](https://www.gnu.org/software/bash/)

<img width="700" src="maildir-to-mbox-cover.webp" alt="Maildir to MBOX Converter" />

**Maildir to MBOX Converter v2.1.0** e uma ferramenta CLI para Linux que converte arvores `Maildir` de servidores Dovecot/cPanel (incluindo `cur/`, `new/` e subpastas como `.Sent`, `.Drafts` e `.Archive.2026`) em arquivos `MBOX` compativeis com Mozilla Thunderbird, Apple Mail e rotinas de backup/migracao.

---

## Funcionalidades

- **Preservacao Completa da Hierarquia**: converte a raiz Maildir em `INBOX` e mapeia subpastas com ponto (ex.: `.Archive.2026` -> `Archive-2026`), preservando pastas vazias como arquivos MBOX zerados para reconhecimento no Thunderbird
- **Conversao Compativel com RFC**: delega leitura e lock de caixas aos modulos nativos `mailbox.Maildir` e `mailbox.mbox` do Python 3 com passagem segura via `sys.argv` (sem risco de injecao)
- **Conversao de `cur/` e `new/`**: captura automaticamente mensagens lidas e nao lidas
- **Controle de CPU em Producao (`-p slow|fast`)**: padrao `slow` (`nice 19`) para evitar degradacao de I/O e CPU em servidores cPanel/Dovecot ativos
- **Armazenamento Seguro (`chmod 600`)**: gera o arquivo `.tar.gz` (ou diretorio com `--no-compress`) com permissao restrita ao proprietario, sem expor backups de e-mail em diretorios web publicos
- **Simulacao Dry-Run (`--dry-run`)**: mapeia pastas e conta mensagens sem gravar nada em disco
- **Relatorios Multi-Formato (`-o table|json|csv`)**: tabela ASCII, JSON para automacoes ou CSV para auditorias de migracao

---

## Requisitos

- Linux com Bash 4+
- `python3` (modulo nativo `mailbox`, sem pacotes externos)
- `tar` e `find`

---

## Instalacao

```bash
curl -fsSLO https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh
chmod +x maildir-mbox.sh
```

---

## Uso

```bash
./maildir-mbox.sh [OPCOES]

Opcoes:
  -s, --source DIR        Caminho da raiz Maildir (com cur/ ou new/) [padrao: .]
  -d, --dest PATH         Arquivo .tar.gz de destino (ou diretorio com --no-compress)
  -p, --profile MODO      Prioridade de CPU: slow (nice 19, padrao) ou fast (nice 0)
  --no-compress           Mantem os arquivos MBOX em diretorio sem compactar em .tar.gz
  --dry-run               Inspeciona o Maildir e exibe o plano sem gravar arquivos
  -o, --output FORMATO    Formato de saida: table (padrao), json, csv
  -q, --quiet             Suprime saida padrao (mantem erros em stderr)
  --no-color              Desativa cores ANSI
  -V, --version           Exibe a versao e encerra
  -h, --help              Exibe a ajuda e encerra
```

### Exemplos

```bash
# Simular mapeamento de pastas e contagem de mensagens sem gravar em disco
./maildir-mbox.sh -s /home/usuario/mail/exemplo.com.br/contato --dry-run

# Converter com seguranca em producao (padrao nice 19) gerando arquivo chmod 600
./maildir-mbox.sh -s /home/usuario/mail/exemplo.com.br/contato -d /root/backups/contato.tar.gz

# Conversao rapida com saida JSON para pipelines
./maildir-mbox.sh -s /home/usuario/mail/exemplo.com.br/contato -p fast -o json

# Exportar MBOX sem compactacao com relatorio CSV de auditoria
./maildir-mbox.sh -s /home/usuario/mail/exemplo.com.br/contato --no-compress -d /root/mbox_out -o csv
```

---

## Exemplo de Saida Real

Capturado em servidor AlmaLinux 8.10 com cPanel/WHM:

### Saida em tabela (padrao)

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

### Simulacao Dry-Run (`--dry-run`)

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

### Saida JSON (`-o json`)

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

### Saida CSV (`--no-compress -o csv`)

```csv
timestamp,account,profile,dry_run,source_folder,mbox_name,found,converted,failed,status
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,".","INBOX",2,2,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Archive.2026","Archive-2026",1,1,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Drafts","Drafts",0,0,0,EMPTY
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Sent","Sent",1,1,0,CONVERTED
2026-11-20T05:31:17Z,"contato@perciocastelo.com.br",slow,false,"./.Trash","Trash",0,0,0,EMPTY
```

---

## Licenca

Apache-2.0. Consulte [LICENSE](LICENSE) para detalhes.

## Autor

[Percio Castelo](https://perciocastelo.com.br)
