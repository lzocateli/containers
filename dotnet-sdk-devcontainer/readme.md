- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/dotnet-sdk
```

Tag version:
```
8.0.410-jammy-dev
```

Local para o dockerfile:
```
containers/dotnet-sdk
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```


- Copiar uma imagem de um registro para outro localmente sem enviar a nova imagem para o novo registro.


1. **Puxe a imagem do registro original**:
    ```sh
    docker pull nome-docker.artifacts.seudominio.com/repoimagem/dotnetcore/sdk-8.0.303-jammy-devcontainer:1.0.0
    ```

2. **Tagueie a imagem com o novo nome**:
    ```sh
    docker tag nome-docker.artifacts.seudominio.com/repoimagem/dotnetcore/sdk-8.0.303-jammy-devcontainer:1.0.0 lzocateli/dotnet-sdk:8.0.303-jammy-amd64
    ```

3. **Salve a imagem localmente**:
    ```sh
    docker save -o dotnet-sdk-8.0.303-jammy-amd64.tar lzocateli/dotnet-sdk:8.0.303-jammy-amd64
    ```

4. **Carregue a imagem salva**:
    ```sh
    docker load -i dotnet-sdk-8.0.303-jammy-amd64.tar
    ```
