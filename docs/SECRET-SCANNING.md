# Protecao contra secrets

Este repositorio usa Gitleaks para detectar tokens, senhas, chaves privadas,
connection strings e outras credenciais no estado atual, no conteudo staged e
em todo o historico Git. A protecao e complementar ao Trivy e ao Secret
Scanning do GitHub; nao depende de plano pago do GitHub.

## Componentes

- `tools/scripts/secret-scan.sh`: scanner local com Gitleaks 8.30.1.
- `.githooks/pre-commit`: bloqueia commits com achados staged.
- `.github/workflows/secret-scan.yml`: examina todo o historico em push, pull
  request, execucao manual e semanalmente.
- O CI usa `ubuntu-24.04`, checkout com `fetch-depth: 0` e a imagem fixada
  `zricethezav/gitleaks:v8.30.1` quando o binario local nao esta disponivel.

## Instalar o hook

A configuracao de hooks e local ao clone e nao e ativada automaticamente pelo
Git. Na raiz do repositorio, execute:

```bash
git config core.hooksPath .githooks
```

Confirme:

```bash
git config --get core.hooksPath
```

O hook chama `tools/scripts/secret-scan.sh --staged` antes de cada commit. Ele
nao envia arquivos para servico externo. O fallback Docker monta o repositorio
como somente leitura.

## Executar manualmente

```bash
# Ajuda
bash tools/scripts/secret-scan.sh --help

# Historico completo de todas as refs locais
bash tools/scripts/secret-scan.sh --history

# Alteracoes preparadas para commit
bash tools/scripts/secret-scan.sh --staged

# Arquivos atuais de um diretorio
bash tools/scripts/secret-scan.sh --dir .

# Planejamento sem executar o scanner
bash tools/scripts/secret-scan.sh --dry-run
```

O log de cada execucao fica em `.tmp/` e e ignorado pelo Git. A saida usa
redacao (`--redact`) para nao registrar o valor encontrado.

Quando existem achados, o script tambem cria um JSON redigido em `.tmp` e
imprime somente `path`, `commit`, `rule` e `line`. Use esses caminhos para
escolher `--path` ou preparar `--replace-text`; nunca use o segredo no comando.

## Windows com Docker Desktop

Com Docker Desktop em execucao e Git for Windows ou WSL instalado, o script
detecta `docker.exe` automaticamente e monta o clone como somente leitura. Na
raiz do repositorio, execute pelo Git Bash ou WSL:

```bash
bash tools/scripts/secret-scan.sh --history
bash tools/scripts/secret-scan.sh --staged
bash tools/scripts/secret-scan.sh --dir .
```

O bind mount equivalente, executado diretamente no PowerShell, e:

```powershell
$repo = (Get-Location).Path
docker.exe run --rm --read-only `
  --volume "${repo}:/repo:ro" `
  --workdir /repo `
  lzocateli/gitleaks:8.30.1 `
  git --redact --log-opts="--all" .
```

Para examinar um diretorio especifico pelo PowerShell:

```powershell
$repo = (Get-Location).Path
docker.exe run --rm --read-only `
  --volume "${repo}:/repo:ro" `
  lzocateli/gitleaks:8.30.1 `
  dir --redact /repo
```

Para o diff staged, envie o conteudo pelo stdin sem montar o `.git`:

```powershell
git diff --cached --binary | docker.exe run --rm -i --read-only `
  lzocateli/gitleaks:8.30.1 stdin --redact
```

O Docker Desktop precisa estar iniciado e o drive que contém o clone deve estar
compartilhado nas configurações de recursos de arquivo, quando solicitado. A
opcao `--read-only` e o sufixo `:ro` impedem que o scanner altere o clone. O
modo `--rewrite-history` nao usa o container: ele altera o Git local e exige
`git-filter-repo`, working tree limpo e `--confirm-rewrite`.

## Falha do scan

1. Pare o envio e nao copie o valor do segredo para issues, PRs ou logs.
2. Revogue ou rotacione a credencial no provedor imediatamente.
3. Identifique o commit e o caminho no relatorio redigido.
4. Remova o segredo do estado atual e substitua por Secret, OIDC ou variavel de
   ambiente.
5. Se o segredo esteve no historico, avalie a reescrita com `git filter-repo`.
   Reescrever historico exige coordenacao com todos os clones e force push
   autorizado; remover o arquivo nao invalida a credencial.

O CI bloqueia com status diferente de zero quando encontra achados. Nao use
`SKIP`, remova o hook ou adicione excecoes para contornar um segredo real.

## Falsos positivos e testes

Use placeholders inequivocamente ficticios em exemplos. Para um falso positivo
confirmado, prefira uma regra especifica em `.gitleaks.toml` ou uma entrada
justificada em `.gitleaksignore`, com revisao e evidencia no PR. Nunca coloque o
valor real em uma allowlist. Testes que precisam de padroes semelhantes devem
usar valores claramente invalidos e documentar a razao.

## Limites

Gitleaks nao revoga credenciais, nao limpa clones existentes e nao substitui a
notificacao do provedor. O scan historico depende das refs presentes no clone;
o workflow garante todas as refs disponiveis no checkout completo. Tags e refs
remotas removidas anteriormente podem exigir uma coleta ou auditoria separada.

## Governanca do CI

Configure a protecao da branch `main` para exigir o check `Gitleaks no
historico` e confirme em **Actions** que o workflow e o agendamento semanal
estao ativos.

## Remediar o historico

A remocao deve ser usada somente depois de revogar/rotacionar a credencial.
Instale `git-filter-repo` e garanta que o working tree esteja limpo. O script
nao executa a operacao sem `--confirm-rewrite`.

Para remover um arquivo ou diretorio de todas as refs:

```bash
bash tools/scripts/secret-scan.sh --rewrite-history --path config/prod.env --dry-run
bash tools/scripts/secret-scan.sh --rewrite-history --path config/prod.env --confirm-rewrite
```

Para substituir valores, use um arquivo conforme a sintaxe do `git-filter-repo`
e mantenha-o fora do Git:

```text
valor-revogado==>***REMOVED***
```

```bash
bash tools/scripts/secret-scan.sh --rewrite-history --replace-text replacements.txt --confirm-rewrite
```

A reescrita altera SHAs, pode remover `origin` e exige coordenacao com todos os
clones antes de um force push. Revise o resultado e execute `--history` novamente.
