### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/oracle
```

Tag version:
```
21-slim
```

Local para o dockerfile:
```
containers/oracle
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

Executar com docker-compose:
```bash
docker-compose up -d
```
