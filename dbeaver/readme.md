### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/dbeaver
```

Tag version:
```
24.0.0
```

Local para o dockerfile:
```
containers/dbeaver
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


```bash
sudo su -

vardbeaver=/var/cloudbeaver/workspace
voldbeaver="$($vardbeaver):/opt/cloudbeaver/workspace"

mkdir -p $vardbeaver
chmod -R 777 /var/cloudbeaver

podman run -d \
    -p 8978:8978 \
    -v $voldbeaver \
    --restart unless-stopped \
    --name cloudbeaver \
    lzocateli/dbeaver:24.0.0
```

Acesse: http://localhost:8978/

### Documentação oficial

https://github.com/dbeaver/cloudbeaver/wiki/Run-Docker-Container

