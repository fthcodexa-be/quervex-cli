<div align="center">

```
 ██████╗ ██╗   ██╗███████╗██████╗ ██╗   ██╗███████╗██╗  ██╗
██╔═══██╗██║   ██║██╔════╝██╔══██╗██║   ██║██╔════╝╚██╗██╔╝
██║   ██║██║   ██║█████╗  ██████╔╝██║   ██║█████╗   ╚███╔╝
██║▄▄ ██║██║   ██║██╔══╝  ██╔══██╗╚██╗ ██╔╝██╔══╝   ██╔██╗
╚██████╔╝╚██████╔╝███████╗██║  ██║ ╚████╔╝ ███████╗██╔╝ ██╗
 ╚══▀▀═╝  ╚═════╝ ╚══════╝╚═╝  ╚═╝  ╚═══╝  ╚══════╝╚═╝  ╚═╝
```

**PostgreSQL recon console** — create, connect to and explore PostgreSQL databases safely, right from your terminal.

![version](https://img.shields.io/badge/version-1.0.1-00f0ff)
![platforms](https://img.shields.io/badge/platforms-windows%20%7C%20linux%20%7C%20WSL%20%7C%20macOS-7a5cff)
![price](https://img.shields.io/badge/price-free-39ff14)
![license](https://img.shields.io/badge/license-MIT-ff00c8)

</div>

This repository contains the **installers** of QUERVEX. QUERVEX is free: no account, no subscription, no telemetry.

## Install

No administrator rights are needed. Afterwards, open a **new** terminal and type `quervex`.

### Windows

| Method | How |
|---|---|
| Setup program | download [`quervex-setup-windows-x64.exe`](https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.1/quervex-setup-windows-x64.exe) and double-click it |
| PowerShell, one line | `irm https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.1/install.ps1 \| iex` |
| From this repository | double-click `windows\install.cmd` |

QUERVEX goes to `%LOCALAPPDATA%\Programs\quervex` and that folder is added to *your* PATH. The program is not code-signed yet: if SmartScreen warns you, choose *More info → Run anyway*. Restart VS Code (or any app with an open terminal) so it sees the new PATH.

### Linux, WSL, macOS

| Method | How |
|---|---|
| One line | `curl -fsSL https://github.com/fthcodexa-be/quervex-cli/releases/download/v1.0.1/install.sh \| sh` |
| From this repository | `sh unix/install.sh` |
| Setup program (Linux, WSL) | download `quervex-setup-linux-x64` (or `-arm64`) from the [release](https://github.com/fthcodexa-be/quervex-cli/releases/tag/v1.0.1), then `chmod +x quervex-setup-linux-x64 && ./quervex-setup-linux-x64` |

QUERVEX goes to `~/.local/bin/quervex`; the installer offers to add that folder to your PATH. On macOS, QUERVEX is installed with npm for now (Node.js ≥ 22 required).

### npm (any system with Node.js ≥ 22)

```sh
npm install -g quervex
```

## Check your download

Every installer verifies the SHA-256 fingerprint of the program it downloads and refuses a file that does not match. To check a file yourself, compare it with [`SHA256SUMS.txt`](SHA256SUMS.txt):

```sh
# Windows (PowerShell)
Get-FileHash .\quervex-setup-windows-x64.exe -Algorithm SHA256
# Linux, WSL, macOS
sha256sum quervex-setup-linux-x64     # macOS: shasum -a 256 <file>
```

## Uninstall

| System | How |
|---|---|
| Windows | double-click `windows\uninstall.cmd` (or `powershell -ExecutionPolicy Bypass -File windows\uninstall.ps1 -Purge` to also delete `~\.quervex`) |
| Linux, WSL, macOS | `sh unix/uninstall.sh` (add `--purge` to also delete `~/.quervex`) |
| npm | `npm uninstall -g quervex` |

## First steps

```text
quervex            start the console
/config add        add a connection (step-by-step wizard)
/                  list every command
/help              help
```

Terms of use and privacy: `/legal` in the console. QUERVEX collects no data: everything stays on your machine.
To report a vulnerability, please contact the author privately through [fabianthiry.be](https://fabianthiry.be/en) rather than opening a public issue.

## License

[MIT](LICENSE) © Fabian Thiry. Bundled third-party licenses: [`THIRD-PARTY-NOTICES.txt`](THIRD-PARTY-NOTICES.txt) (npm packages) and [`NODE-LICENSE.txt`](NODE-LICENSE.txt) (the Node.js runtime embedded in the `quervex-setup-*` programs).
