### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/cockpit
```

Tag version:
```
314
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
sudo su -
apt remove cockpit
apt autoremove
apt install -y cockpit-system cockpit-bridge cockpit-podman

podman rmi $(podman images --filter=reference=lzocateli/cockpit -q) -f

podman run -d \
  --privileged \
  -p 9091:9090 \
  -v /:/host \
  --pid=host \
  --name cockpit-ws \
  lzocateli/cockpit:314
```
