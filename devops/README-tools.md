# Tutorial: 1Password CLI (`op`)

Este guia apresenta os comandos mais usados da CLI do 1Password para consultar cofres e itens, além de consumir secrets em scripts sem gravar valores em texto puro no codigo.

## Disponibilidade

A imagem `lzocateli/devops` instala a CLI `op`. No shell do container, confira a instalacao e a ajuda:

```bash
op --version
op --help
op item --help
```

Para obter ajuda de um comando especifico, acrescente `--help`, por exemplo `op item get --help`.

## Autenticacao

### Uso interativo

Em uma maquina com o aplicativo 1Password configurado para integrar com a CLI, o comando abaixo inicia ou confirma a autenticacao:

```bash
op signin
op whoami
```

O `op signin` interativo depende da integracao com o aplicativo desktop. Essa integracao do host nao e automaticamente compartilhada com um container Linux.

### Container, CI e automacao

Para uso headless, utilize uma Service Account com acesso somente aos cofres necessarios. Injete o token no processo como `OP_SERVICE_ACCOUNT_TOKEN`, usando o mecanismo de secrets do executor, CI ou plataforma de containers. Depois valide a identidade:

```bash
op whoami
```

#### Criar e obter o token

No 1Password.com, abra **Developer > Directory**, escolha **Other** e selecione **Create a Service Account**. Defina um nome, uma validade e somente os cofres e permissoes necessarios. O token e exibido uma unica vez; use **Save in 1Password** para guarda-lo imediatamente em um item seguro. Se voce nao puder criar Service Accounts, solicite a um administrador que crie uma com acesso restrito e compartilhe o token por um canal seguro.

Tambem e possivel criar uma pelo CLI, se sua conta tiver permissao administrativa. Este exemplo concede somente leitura ao cofre `Development` e expira em 30 dias:

```bash
op service-account create "devops-local" --expires-in 30d --vault "Development:read_items"
```

O comando retorna o token uma unica vez. Salve-o imediatamente no 1Password ou no gerenciador de secrets aprovado; nao o copie para arquivos, comandos, tickets ou logs.

#### Carregar temporariamente no PowerShell

Copie o token do item seguro e execute o trecho abaixo na mesma sessao PowerShell em que usara `op`. O prompt nao mostra o que voce digita; a variavel fica disponivel para o wrapper `FunOp`, que a encaminha ao container:

```powershell
$secureToken = Read-Host 'Token da Service Account' -AsSecureString
$tokenPointer = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($secureToken)
try {
  $env:OP_SERVICE_ACCOUNT_TOKEN = [Runtime.InteropServices.Marshal]::PtrToStringBSTR($tokenPointer)
}
finally {
  [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($tokenPointer)
  $secureToken.Dispose()
}

op whoami
```

A variavel de ambiente e necessaria para o container receber o token, portanto ele fica acessivel ao processo PowerShell enquanto definido. Ao terminar, remova-o da sessao:

```powershell
Remove-Item Env:OP_SERVICE_ACCOUNT_TOKEN
```

Para CI ou automacao, cadastre o valor diretamente no gerenciador de secrets da plataforma e injete-o no processo. Nao o salve como variavel permanente do Windows.

Nao coloque o token no Dockerfile, em `ARG`/`ENV`, no Compose, em arquivos versionados, na linha de comando ou em logs. Tokens sao credenciais: limite o acesso e a validade, e revogue/rotacione se houver exposicao. A Service Account so mostra o token durante sua criacao; armazene-o imediatamente em um cofre seguro.

## Contas e cofres

Liste as contas configuradas, a identidade ativa e os cofres acessiveis:

```bash
op account list
op whoami
op vault list
op vault get "Development"
```

Os comandos aceitam nomes ou IDs. IDs sao preferiveis em automacoes quando nomes podem se repetir.

## Itens

Liste itens, filtre por cofre ou categoria, e consulte um item:

```bash
op item list
op item list --vault "Development"
op item list --categories Login --vault "Development"
op item get "GitHub" --vault "Development"
```

Para retornar somente campos especificos:

```bash
op item get "GitHub" --vault "Development" --fields label=username,label=password
```

Esse ultimo comando revela o valor do campo no terminal. Evite executa-lo em sessoes gravadas, logs de CI ou pipelines que preservem stdout.

Crie um item Login sem fornecer uma senha literal na linha de comando:

```bash
op item create \
  --category=login \
  --title="Aplicacao de desenvolvimento" \
  --vault="Development" \
  --url="https://example.com" \
  --generate-password \
  username=usuario@example.com
```

Edite ou arquive um item existente:

```bash
op item edit "Aplicacao de desenvolvimento" --vault="Development" --title="Aplicacao interna"
op item delete "Aplicacao antiga" --vault="Development" --archive
```

`op item delete` sem `--archive` exclui o item. Confira o nome, ID e cofre antes de executar operacoes que alteram dados. Evite passar valores sensiveis como atribuicoes (`campo=valor`): argumentos podem ficar no historico do shell ou visiveis para outros processos. Para esses casos, prefira templates JSON e proteja/remova os arquivos temporarios.

## Secret references

Uma secret reference identifica um campo sem conter seu valor:

```text
op://<cofre>/<item>/<campo>
```

Exemplo: `op://Production/PostgreSQL/password`. O nome do cofre, item, secao e campo deve corresponder ao que existe no 1Password. Coloque referencias com espacos entre aspas.

### Ler um campo

```bash
op read "op://Production/PostgreSQL/password"
```

O comando imprime o secret no stdout. Use-o diretamente apenas quando o processo consumidor precisar do valor e stdout nao for registrado. Para uso automatizado, prefira `op run`.

### Executar um processo com secrets

Defina variaveis com referencias e execute o processo por meio de `op run`. Os valores resolvidos ficam disponiveis ao processo filho durante sua execucao:

```bash
export DB_PASSWORD="op://Production/PostgreSQL/password"
op run -- ./start-application.sh
```

Tambem e possivel usar um arquivo de ambiente local que contenha referencias, nunca valores em texto puro:

```dotenv
DB_PASSWORD=op://Production/PostgreSQL/password
```

```bash
op run --env-file=.env -- ./start-application.sh
```

Mantenha `.env` ignorado pelo Git, mesmo quando ele contem somente referencias, e nao use `--no-masking` em ambientes compartilhados. A mascara de stdout/stderr e uma protecao adicional, nao substitui o cuidado com logs e processos filhos.

### Injetar em arquivo de configuracao

Para uma aplicacao que exige arquivo, crie um template com referencias entre `{{ }}`:

```yaml
database:
  password: "{{ op://Production/PostgreSQL/password }}"
```

Resolva o template apenas em runtime:

```bash
op inject --in-file config.yml.tpl --out-file /run/app/config.yml
```

O arquivo de saida contem secrets em texto puro. Restrinja permissoes, grave somente em armazenamento temporario protegido e remova-o assim que nao for mais necessario. Nunca versione o arquivo resolvido.

## JSON e automacao

Use `--format json` para integrar com ferramentas que leem JSON. A imagem `devops` inclui `jq`:

```bash
op item list --vault "Development" --format json | jq '.[].title'
```

Em scripts, prefira IDs, delimite o cofre, valide codigos de saida e nao habilite trace (`set -x`) ao processar secrets. Evite `--debug` em sessoes que possam ser registradas.

## Comandos de referencia rapida

| Objetivo | Comando |
| --- | --- |
| Versao e ajuda | `op --version`, `op --help` |
| Autenticacao interativa | `op signin`, `op whoami` |
| Contas e cofres | `op account list`, `op vault list`, `op vault get <cofre>` |
| Listar e consultar itens | `op item list`, `op item get <item>` |
| Criar, editar e arquivar | `op item create`, `op item edit`, `op item delete --archive` |
| Ler campo por referencia | `op read <secret-reference>` |
| Executar com secrets | `op run -- <comando>` |
| Resolver template | `op inject --in-file <template> --out-file <arquivo>` |
| Completacao do Zsh | `eval "$(op completion zsh)"; compdef _op op` |

## Problemas comuns

- **Nao autenticado:** execute `op whoami`; em container/CI verifique se `OP_SERVICE_ACCOUNT_TOKEN` foi injetado no processo.
- **Cofre ou item nao encontrado:** confirme os nomes/IDs e o escopo de acesso da Service Account. Ao usar Service Account, especifique o cofre quando o comando exigir ou quando houver nomes repetidos.
- **Secret reference invalida:** confira a grafia e a estrutura `op://cofre/item/secao/campo`; caracteres especiais e espacos podem exigir aspas.
- **Secret aparece em log:** remova a impressao do valor, a expansao por `echo`/`printenv`, o modo trace e qualquer opcao que desative a mascara.

## Documentacao oficial

- [Primeiros passos com a CLI](https://www.1password.dev/cli/get-started/)
- [Referencia dos comandos](https://www.1password.dev/cli/reference/)
- [Carregar secrets em scripts](https://www.1password.dev/cli/secrets-scripts/)
- [Service Accounts](https://www.1password.dev/service-accounts/get-started/)
