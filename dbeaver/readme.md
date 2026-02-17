- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
dbeaver
```

Tag version:
```
25.2.0
```
Your Dockerfile repositories:
```
containers
```
Local para o dockerfile:
```
containers/dbeaver
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.xxx.com:80 --build-arg Env_NoProxy=xxx.com
```

Baypass proxy:
```
xxx\.com
```

- No Windows com docker desktop

Primeiro, crie as variáveis de ambiente no contexto do usuário e as pastas necessárias:
```powershell
# Definir as variáveis
$vardbeaver = "$env:USERPROFILE\cloudbeaver\workspace"

# Criar a pasta workspace se não existir
if (!(Test-Path $vardbeaver)) {
    New-Item -ItemType Directory -Path $vardbeaver -Force
    Write-Host "Pasta criada: $vardbeaver"
} else {
    Write-Host "Pasta já existe: $vardbeaver"
}

# Definir as variáveis no contexto do usuário (persistente)
[Environment]::SetEnvironmentVariable("DBEAVER_WORKSPACE", $vardbeaver, "User")
Write-Host "Variável DBEAVER_WORKSPACE definida no contexto do usuário: $vardbeaver"
```

Em seguida, execute o container:
```powershell
docker run -d `
    -p 8978:8978 `
    -v "$env:DBEAVER_WORKSPACE:/opt/cloudbeaver/workspace" `
    --restart unless-stopped `
    --name cloudbeaver `
   lzocateli/dbeaver:25.2.0
```

Acesse: http://localhost:8978/

### Documentação oficial

https://github.com/dbeaver/cloudbeaver/wiki/Run-Docker-Container

