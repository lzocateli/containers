# CloudBeaver — Build e execução local

Imagem baseada em `dbeaver/cloudbeaver:26.1.4` com o driver JDBC do Snowflake (`3.22.0`) pré-instalado.

**Registry:** `lzocateli/cloudbeaver`

---

## 1. Pré-requisitos

- Docker Desktop instalado e em execução
- Acesso ao registry (`lzocateli`)
- Acesso à internet via proxy `proxy.xxx.com:80` (necessário durante o build para baixar o JDBC do Snowflake)

---

## 2. Autenticar no registry

```powershell
docker login lzocateli
```

---

## 3. Build da imagem localmente

Execute a partir da pasta `containers/cloudbeaver/`:

```powershell
$IMAGE = "lzocateli/cloudbeaver"
$TAG   = "26.1.4"

docker build `
    --platform linux/amd64 `
    --build-arg Env_HttpProxy=proxy.xxx.com:80 `
    --build-arg Env_HttpsProxy=proxy.xxx.com:80 `
    --build-arg Env_NoProxy=dominio.com `
    -t "$($IMAGE):$($TAG)" `
    .
```

> **Nota:** o build baixa o JAR do Snowflake JDBC diretamente do Maven Central via proxy corporativo.
> Se o ambiente não tiver acesso, baixe o JAR manualmente e use `COPY` no Dockerfile.

---

## 4. Push para o registry

```powershell
docker push "$($IMAGE):$($TAG)"
```

---

## 5. Executar localmente com Docker Desktop

> **Persistência:** Todos os dados do CloudBeaver (usuários, conexões, credenciais, configurações)
> ficam no diretório `workspace` montado via bind mount. Você pode trocar a versão da imagem ou
> remover/recriar o container sem perder nenhuma informação — basta apontar o mesmo diretório.

### 5.1 Criar a pasta de workspace (primeira vez)

```powershell
$vardbeaver = "$env:USERPROFILE\cloudbeaver\workspace"

if (!(Test-Path $vardbeaver)) {
    New-Item -ItemType Directory -Path $vardbeaver -Force
}

# Converte o path Windows para o ponto de montagem da distro docker-desktop
# (drives ficam em /mnt/host/<letra>/ e não em /mnt/<letra>/)
$wslPath = "/mnt/host/" + $vardbeaver[0].ToString().ToLower() + ($vardbeaver.Substring(2) -replace '\\', '/')
wsl -d docker-desktop -- mkdir -p "$wslPath"
wsl -d docker-desktop -- chmod -R 777 "$wslPath"

[Environment]::SetEnvironmentVariable("DBEAVER_WORKSPACE", $vardbeaver, "User")
$env:DBEAVER_WORKSPACE = $vardbeaver
Write-Host "DBEAVER_WORKSPACE definido: $vardbeaver"
```

> **Importante:** A variável `DBEAVER_WORKSPACE` só fica disponível em novos terminais. O bloco
> acima já define na sessão atual via `$env:DBEAVER_WORKSPACE = $vardbeaver`.

### 5.2 Executar o container

- Descubra qual o IP do servidor DNS

```powershell
nslookup blog.zocate.li
```

```powershell
$IMAGE = "lzocateli/cloudbeaver"
$TAG   = "26.1.4"

# Garante que o path está definido (fallback se a variável de ambiente não existir)
$WORKSPACE = if ($env:DBEAVER_WORKSPACE) { $env:DBEAVER_WORKSPACE } else { "$env:USERPROFILE\cloudbeaver\workspace" }

docker run -d `
    -p 8978:8978 `
    --dns 137.230.255.248 `
    --cap-add=NET_ADMIN `
    -v "${WORKSPACE}:/opt/cloudbeaver/workspace" `
    --restart unless-stopped `
    --name cloudbeaver `
    "$($IMAGE):$($TAG)"
```

Acesse: http://localhost:8978/

### 5.3 Atualizar para uma nova versão (sem perder dados)

```powershell
docker stop cloudbeaver
docker rm cloudbeaver

# Altere $TAG para a nova versão e execute o build (seção 3) e depois 5.2
```

---

## 6. Pipeline CI/CD (Azure DevOps)

Parâmetros para o pipeline de build corporativo:

| Parâmetro | Valor |
|---|---|
| Nome da imagem | `cloudbeaver` |
| Tag | `26.1.4` |
| Repositório | `lzocateli/containers` |
| Caminho do Dockerfile | `containers/cloudbeaver` |
| Build args | `--build-arg Env_HttpProxy=proxy.xxx.com:80 --build-arg Env_NoProxy=dominio.com` |
| Bypass proxy | `dominio\.com` |

---

## Referências

- [CloudBeaver — Run Docker Container](https://github.com/dbeaver/cloudbeaver/wiki/Run-Docker-Container)
- [Snowflake JDBC — Maven Central](https://repo1.maven.org/maven2/net/snowflake/snowflake-jdbc/)
- [Drivers Management no CloudBeaver](https://github.com/dbeaver/cloudbeaver/wiki/Drivers-Management)
