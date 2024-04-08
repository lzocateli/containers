- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/azure-cli
```

Tag version:
```
2.59.0-amd64
```

Local para o dockerfile:
```
containers/azure-cli
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```

## Exemplo de uso

- Crie dois alias, um para o comando `az` e outro para  o comando `jq`, veja aqui [https://github.com/lzocateli/containers] como criar alias (super comandos com docker)

```bash
az devops security group list --org https://dev.azure.com/nuuvers --scope organization --subject-types aadgp | jq '.[] | {displayName: .displayName, description: .description}'
```
