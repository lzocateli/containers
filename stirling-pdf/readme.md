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

podman rm stirling-pdf -f

docker run -d \
  -p 8080:8080 \
  -v /location/of/trainingData:/usr/share/tessdata \
  -v /location/of/extraConfigs:/configs \
  -v /location/of/logs:/logs \
  -e DOCKER_ENABLE_SECURITY=false \
  -e INSTALL_BOOK_AND_ADVANCED_HTML_OPS=false \
  -e LANGS=en_GB \
  --name stirling-pdf \
  frooodle/s-pdf:latest

  Can also add these for customisation but are not required
  -v /location/of/customFiles:/customFiles \
```
