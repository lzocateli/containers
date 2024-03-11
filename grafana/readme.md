### Documentação para uso da imagem

Use o parametro `-it` no lugar `-d` para executar em modo iterativo


```bash
podman run --name grafana-10.2.2 \
    -d \
    lzocateli/grafana-10.2.2-ubuntu:1.0.0
```

- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/grafana-10.2.2-ubuntu
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/grafana
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
nuuvify\.com
```
