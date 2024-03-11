## Criação da imagem

- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
nginx-geoipupdate
```

Tag version:
```
v6.1.0-amd64
```

Local para o dockerfile:
```
containers/nginx-geoip2
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```

---
---

## Documentação original
https://github.com/maxmind/geoipupdate

- Exemplo:

```
docker run --env-file <file> -v <database directory>:/usr/share/GeoIP ghcr.io/maxmind/geoipupdate:v6.1.0-amd64
```

- Exemplo para download manual usando a `License Key`
https://dev.maxmind.com/geoip/updating-databases?lang=en

## Script para executar o container

- RunGeoIpUpdate.ps1

Pipeline: `pipelines-store/pipeline-templates/execute-geoip2-update.yml`


```bash
podman run -d \
    --env-file /userapps/configs/geoip2/geoip2.env \
    -v /userapps/configs/geoip2/data:/usr/share/GeoIP \
    --name geoipupdate \
    lzocateli/nginx-geoipupdate:v6.1.0-amd64
```
