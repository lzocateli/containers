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

## Verificar se tem algum serviço usando a porta 53
```bash
sudo lsof -i -P -n | grep LISTEN
```

## Para desabilitar o serviço systemd-resolved no Ubuntu Server 22.04, siga estes passos:
- Desabilitar e parar o serviço:
```bash
sudo systemctl disable systemd-resolved.service
sudo systemctl stop systemd-resolved.service
```
- Remover o link simbólico do resolv.conf:
```bash
sudo rm /etc/resolv.conf
```
- Criar um novo link simbólico para o resolv.conf:
```bash
sudo ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
```
- Reiniciar o NetworkManager:
```bash
sudo systemctl restart NetworkManager
```
Esses comandos irão desabilitar o systemd-resolved e garantir que o sistema utilize o arquivo resolv.conf padrão para a resolução de nomes DNS
