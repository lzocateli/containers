## Para criar alias ou super comandos com docker/podman

- Editar o arquivo `~/.bash_aliases`
  Ele precisa estar sendo referenciado no `.zshrc` ou `.bashrc`

```bash
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi
``` 

```bash
alias terraform='podman run --rm -it -v "$(pwd):/workspace" -w /workspace hashicorp/terraform:1.3.7 "$@"'
alias az='podman run --rm -it -v ~/.ssh:/root/.ssh -v ~/.azure:/root/.azure -v ~/.azure-devops:/root/.azure-devops -v "$(pwd):/workspace" -w /workspace lzocateli/azure-cli:2.59.0-amd64 az "$@"'
alias jq='podman run --rm -it -v ~/.ssh:/root/.ssh -v ~/.azure:/root/.azure -v ~/.azure-devops:/root/.azure-devops -v "$(pwd):/workspace" -w /workspace lzocateli/azure-cli:2.59.0-amd64 jq "$@"'
alias ng='podman run --rm -it -v "$(pwd):/workspace" -w /workspace -v /tmp/ng:/tmp/ng alexsuch/angular-cli:12.2.18 ng "$@"'
alias node='podman run --rm -it -v "$(pwd):/workspace" -w /workspace node:16.17.1-alpine3.16 "$@"'
alias npm='podman run --rm -it -v "$(pwd):/workspace" -w /workspace -v ~/.npmrc:/root/.npmrc -v ~/npm-cache:/root/.npm -v /tmp/npm:/tmp/npm node:16.17.1-alpine3.16 npm "$@"'
```

- Para powershell
  Editar ou criar o arquivo `C:\Users\seuusuario\Documentos\WindowsPowerShell\profile.ps1`
  
```powershell
function FunAzCli { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$($HOME)/.ssh:/root/.ssh" -v "$($HOME)/.azure:/root/.azure" -v "$($HOME)/.azure-devops:/root/.azure-devops" -v "$(Get-Location):/workspace" -w /workspace lzocateli/azure-cli:2.59.0-amd64 az $Args
}
function FunAzCliJQ { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$($HOME)/.ssh:/root/.ssh" -v "$($HOME)/.azure:/root/.azure" -v "$($HOME)/.azure-devops:/root/.azure-devops" -v "$(Get-Location):/workspace" -w /workspace lzocateli/azure-cli:2.59.0-amd64 jq $Args
}

function FunTerraform { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$(Get-Location):/workspace" -w /workspace hashicorp/terraform:1.3.7 $Args
}

function FunNgCli { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$(Get-Location):/workspace" -w /workspace -v "$($TEMP)/ng:/tmp/ng" alexsuch/angular-cli:12.2.18 ng $Args
}

function FunNode { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$(Get-Location):/workspace" -w /workspace cat-docker.artifacts.cat.com/cat_brazil-jfrog/node/14.21.1-alpine-3.16:1.0.0 $Args
}

function FunNPN { 
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$(Get-Location):/workspace" -w /workspace -v "$($HOME)/.npmrc:/root/.npmrc" -v "$($APPDATA)/npm-cache:/root/.npm" -v "$($TEMP)/npm:/tmp/npm" cat-docker.artifacts.cat.com/cat_brazil-jfrog/node/14.21.1-alpine-3.16:1.0.0 npm $Args
}

function GithubCli {
  C:\'Program Files'\Docker\Docker\resources\bin\docker.exe run --rm -it -v "$(Get-Location):/workspace" -w /workspace -v "$($HOME)/.config/gh:/root/.config/gh" ghcr.io/supportpal/github-gh-cli:2.31.0 gh $Args
}

Set-Alias gh GithubCli -Option AllScope
Set-Alias terraform FunTerraform -Option AllScope
Set-Alias jq FunAzCliJQ -Option AllScope
Set-Alias az FunAzCli -Option AllScope
Set-Alias ng FunNgCli -Option AllScope
Set-Alias node FunNode -Option AllScope
Set-Alias npm FunNPN -Option AllScope
```
