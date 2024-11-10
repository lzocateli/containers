- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/stirling-pdf
```

Tag version:
```
0.32.0
```

Local para o dockerfile:
```
containers/stirling-pdf
```

Imagem argumentos:
```
  --build-arg Env_HttpProxy=proxy.nuuvify.com:80 --build-arg Env_NoProxy=nuuvify.com
```

Baypass proxy:
```
  nuuvify\.com
```

### Para executar o container

```bash
#!/bin/bash

mkdir -p ~/userapps/stirling-pdf/logs ~/userapps/stirling-pdf/extraConfigs ~/userapps/stirling-pdf/trainingData
podman rm stirling-pdf -f

docker run -d \
  -v ~/userapps/stirling-pdf/trainingData:/usr/share/tessdata \
  -v ~/userapps/stirling-pdf/extraConfigs:/configs \
  -v ~/userapps/stirling-pdf/logs:/logs \
  -e DOCKER_ENABLE_SECURITY=false \
  -e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
  -e LANGS=pt_BR \
  --restart unless-stopped \
  --name stirling-pdf \
  --network=lzo \
  lzocateli/stirling-pdf:0.32.0


#  Can also add these for customisation but are not required
#  -p 8080:8080 \
#  -v /location/of/customFiles:/customFiles \
```
