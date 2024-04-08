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
