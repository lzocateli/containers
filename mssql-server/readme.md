### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/mssql-server
```

Tag version:
```
2022
```

Local para o dockerfile:
```
containers/mssql-server
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

```bash
version: "3.7"

services:
  sql:
    image: lzocateli/mssql-server:2022
    container_name: mssql
    environment:
      - ACCEPT_EULA=Y
      - SA_PASSWORD=Myadm@12390
      - MSSQL_DATABASE=lzoca
      - MSSQL_DATABASE_COLLATE=SQL_Latin1_General_CP1_CI_AI
      - MSSQL_USER=myuser
      - MSSQL_PASSWORD=Teste@1234
    ports:
      - 1433:1433
    networks:
      - lzo
    volumes:
      - /userapps/configs/db-scripts/:/docker-entrypoint-initdb.d/
    healthcheck:
      test: ["CMD", "/opt/mssql-tools/bin/sqlcmd -U myuser -P Teste@1234 -Q 'SELECT 1'"]
      start_period: 60s
      interval: 60s
      timeout: 10s
      retries: 2

networks:
  lzo:
    name: lzo
    driver: bridge
```
