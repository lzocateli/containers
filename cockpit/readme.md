### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/cockpit
```

Tag version:
```
86
```

Local para o dockerfile:
```
containers/cockpit
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```


### Documentação para uso da imagem

Use o parametro `-it` no lugar `-d` para executar em modo iterativo

- No Linux
```bash
podman run -d \
  --privileged \
  -p 9090:9090 \
  -v /:/host \
  --name cockpit \
  lzocateli/cockpit:86
```

Neste comando:
- `run` é usado para iniciar um novo container.
- `-d` é usado para rodar o container em background (modo "detached").
- `--privileged` dá ao container acesso completo ao host.
- `-v /:/host` monta o diretório raiz do host (`/`) no diretório `/host` dentro do container. Isso permite que o Cockpit no container gerencie o sistema host.
- `-p 9090:9090` mapeia a porta 9090 do container para a porta 9090 do host, permitindo que você acesse o Cockpit através desta porta.
- `--name cockpit_container` dá ao container o nome "cockpit_container".
- `nome_da_imagem` é o nome da imagem Docker que você criou a partir do Dockerfile fornecido.

Por favor, note que este comando deve ser executado como root ou com sudo, pois o Podman precisa de privilégios para acessar o sistema host. Além disso, lembre-se de que executar o Cockpit ou qualquer outra interface de administração do sistema em um container pode ter implicações de segurança, então certifique-se de entender as implicações e tomar as precauções de segurança apropriadas.
