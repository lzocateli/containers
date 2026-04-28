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

```powershell
# Clone o repositório de containers
git clone https://github.com/lzocateli/containers.git
cd containers/oracle

# Build
docker build -t lzocateli/oracle:21-slim .

# Push
docker login
docker push lzocateli/oracle:21-slim
``

```yaml
oracle:
  image: lzocateli/oracle:21-slim
  environment:
    - ORACLE_PASSWORD=${ORACLE_PASSWORD}
    - ORACLE_DATABASE=XEPDB1
    - ORACLE_TABLESPACE=order_data
    - ORACLE_USER=order_api
    - ORACLE_USER_PASSWORD=${ORDER_API_DB_PASSWORD}
  ports:
    - "1521:1521"
  volumes:
    - ${DATA_DIR}/oracle:/opt/oracle/oradata
    - ./scripts:/docker-entrypoint-initdb.d/
  healthcheck:
    test: healthcheck.sh
    start_period: 120s
    interval: 60s
    timeout: 10s
    retries: 3
```

```powershell

```