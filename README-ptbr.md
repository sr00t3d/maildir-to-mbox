# Conversor de Maildir para MBOX

[EN](README.md)

![License](https://img.shields.io/github/license/sr00t3d/maildir-to-mbox) ![Shell Script](https://img.shields.io/badge/language-Bash-green.svg) ![Compatibility](https://img.shields.io/badge/compatible-Dovecot%20%7C%20Thunderbird-blue)

<img width="700" src="maildir-to-mbox-cover.webp" />

Script profissional desenvolvido para automatizar a conversão de caixas de e-mail no formato Maildir (Dovecot) para o formato MBOX, compatível nativamente com o Mozilla Thunderbird, preservando 100% da hierarquia de pastas.

---

## Principais Funcionalidades

Diferente de scripts de conversão simples, este migrador foi construído para cenários reais de Administração de Sistemas (SysAdmin):

- **Detecção Inteligente**: Localiza automaticamente subpastas ocultas (ex: `.Sent`, `.Archive`, `.Work.2023`).
- **Preservação de Hierarquia**: Traduz a estrutura de diretórios separada por pontos do Dovecot para o formato de subpastas do Thunderbird.
- **Segurança Operacional**:
  - Verificação de espaço em disco antes da execução.
  - Perfis de carga de CPU customizados (e.g., `Nice 19`) para evitar impacto em servidores de produção.
  - Contagem regressiva de 5 segundos para cancelamento de emergência.
- **Coleta Automatizada**: Gera um diretório aleatório e um link público temporário para facilitar o download do backup.

---

## Início Rápido (Quick Start)

### Modo hospedado

1. **Baixe o arquivo para o servidor:**

```bash
curl -O https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh
```

2. **Adicione permissão de execução:**

```bash
chmod +x maildir-mbox.sh
```

3. **Execute o script:**

```bash
./maildir-mbox.sh
```

### Modo direto

```bash
bash <(curl -fsSL 'https://raw.githubusercontent.com/sr00t3d/maildir-to-mbox/main/maildir-mbox.sh')
```

### 3. Siga as Instruções na Tela

O script solicitará:

1. O perfil de uso de CPU (Baixo impacto vs. Performance máxima).
2. Confirmação do diretório de destino.

---

## Estrutura de Saída

O script organiza os arquivos Maildir em uma estrutura limpa:
- `INBOX.mbox`
- `Sent.mbox`
- `Drafts.mbox`
- `Subfolder.sbd/` (Hierarquia preservada)

---

## Aviso Legal

> [!WARNING]
> Este software é fornecido "como está". Certifique-se sempre de testar primeiro em um ambiente de desenvolvimento. O autor não se responsabiliza por qualquer uso indevido, consequências legais ou impacto em dados causado por esta ferramenta.

---

## Requisitos

- **SO**: Linux (Debian, Ubuntu, CentOS, RHEL).
- **Dependências**: `bash`, `curl`, `python3` (para o motor de conversão interno).
- **Permissões**: Acesso de leitura ao Maildir de origem e escrita no destino.

## Tutorial Detalhado

Para um guia completo passo a passo, confira meu artigo completo:

👉 [**How to migrate Dovecot to Thunderbird using Maildir-to-MBOX**](https://perciocastelo.com.br/blog/how-to-migrate-dovecot-to-thunderbird-using-maildir-to-mbox.html)

## License

Este projeto está licenciado sob a **GNU General Public License v3.0**. Veja o arquivo [LICENSE](LICENSE) para mais detalhes.