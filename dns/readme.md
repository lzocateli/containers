## Informe os seguintes parametros para gerar a imagem BASE

Nome da Imagem:
```
lzocateli/pihole-unbound
```

Tag version:
```
2024.07.0
```

Local para o dockerfile:
```
containers/pihole/base
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```

## Documentação de referencia

- https://github.com/pi-hole/docker-pi-hole/blob/master/README.md
- https://docs.pi-hole.net/guides/dns/unbound/
- https://github.com/robwithtech/homelab/blob/main/docker%20compose/piholeunbound/pihole-unbound.yml

- Unbound: https://calomel.org/unbound_dns.html

