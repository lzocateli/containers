### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/rclone-onedrive
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/rclone-onedrive
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

- RCLONE_DEST=onedrivelzocateli
  Deve ser o mesmo nome do bloco incluido no arquivo `rclone.conf`

- Use o arquivo docker-compose.yml para executar o container

