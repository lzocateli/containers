### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/certbot
```

Tag version:
```
v2.9.0
```

Local para o dockerfile:
```
containers/certbot
```

Imagem argumentos: (insira 2 espaços a esquerda para não utilizar)
```
  --build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  xyz\.com
```

---

### Para executar o container e gerar/renovar o certificado

- Executa o container para gerar certificados no volume local da sua maquina, em um passo seguinte, copie os certificados gerados na pasta `/userapps/certs/live`, para dentro da pasta usada pelo nginx Exemplo: /userapps/ssl 

- Documentação com os comandos usados: https://eff-certbot.readthedocs.io/en/stable/using.html#where-certs https://eff-certbot.readthedocs.io/en/stable/install.html#running-with-docker

- Video do Luiz Carlos Farias mostra essa aplicabilidade [NGINX: Load Balancer, WebServer, Proxy Reverso, SSL e muito mais](https://www.youtube.com/watch?v=NJ64oO154Zk&t=4203s)


```bash
podman run -i \
--rm \
--name certbot \
-v /userapps/certs:/etc/letsencrypt:z \
-v /userapps/certs/_logs:/var/log/letsencrypt:z \
--entrypoint certbot \
lzocateli/certbot \
certonly \
--webroot \
--webroot-path /etc/letsencrypt \
--noninteractive \
--force-renewal \
-d nuuve.com.br \
-d www.nuuve.com.br \
-d api.nuuve.com.br \
--email lzocateli00@outlook.com \
--agree-tos 
```

- Se for CloudFlare use:

```bash
podman run -i \
--rm \
--name certbot \
-v /userapps/certs:/etc/letsencrypt:z \
-v /userapps/certs/_logs:/var/log/letsencrypt:z \
-v /userapps/.secrets/cloudflare.ini:/root/.secrets/certbot/cloudflare.ini \
--entrypoint certbot \
lzocateli/certbot:v2.9.0 \
  certonly \
  --noninteractive \
  --dns-cloudflare \
  --dns-cloudflare-credentials ~/.secrets/certbot/cloudflare.ini \
  --force-renewal \
  -d zocate.li \
  -d credential.zocate.li \
  --email lzocateli00@outlook.com \
  --agree-tos
```
- Sera necessario criar um token de api com os seguintes acessos, e incluir o token no arquivo cloudflare.ini

![alt](.attachements/Tokens%20de%20API%20de%20usuário%20Cloudflare.png)

-----

- Inclua esses parametros para gerar certificados de teste (invalidos), veja documentação: https://letsencrypt.org/pt-br/docs/staging-environment/

```
--test-cert \
--server https://acme-staging-v02.api.letsencrypt.org/directory
```

- Logo apos a execução do certbot, execute o script abaixo para mover o ultimo certificado e key gerado, para a pasta de destino
  onde o container do nginx através de -v (volume) devera consumir esse certificado.
  Esse script deve ficar em `pipeline-store`

```bash
#Veja o help dentro do script para entender quais parametros são necessarios

./MoveFileLastCreationTime.ps1
```

