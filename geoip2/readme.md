- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
geoipupdate-4.10.0-amdx64
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/geoip2
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insera 2 espaços a esquerda para não utilizar)
```
xyz\.com
```

---

- Pasta com arquivo de configuração e readme.md para executar o container manualmente:
https://dev.azure.com/nuuvers/SharedKernel/_git/SecurityFiles?path=/GeoIP2/readme.md
