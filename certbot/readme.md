### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/certbot ou lzocateli/certbot-dns-cloudflare
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
  lzocateli/certbot:v2.9.0 \
    certonly \
    --webroot \
    --webroot-path /etc/letsencrypt \
    --noninteractive \
    --force-renewal \
    --max-log-backups 5 \
    -d nuuve.com.br \
    -d www.nuuve.com.br \
    -d api.nuuve.com.br \
    --email seuemail@outlook.com \
    --agree-tos 
```

- Se o seu DNS estiver na CloudFlare use o comando abaixo ou o plugin do seu servidor DNS

```bash
podman run -i \
  --rm \
  --name certbot \
  -v /userapps/certs:/etc/letsencrypt:z \
  -v /userapps/certs/_logs:/var/log/letsencrypt:z \
  -v /userapps/.secrets/cloudflare.ini:/root/.secrets/certbot/cloudflare.ini:z \
  --entrypoint certbot \
  lzocateli/certbot-dns-cloudflare:v2.9.0 \
    certonly \
    --noninteractive \
    --dns-cloudflare \
    --dns-cloudflare-credentials /root/.secrets/certbot/cloudflare.ini \
    --force-renewal \
    --max-log-backups 5 \
    -d zocate.li \
    -d credential.zocate.li \
    --email seu_email@xxx.com \
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

- Logo apos a execução do certbot, copie o certificado para a pasta do seu web server, Exemplo:

```bash
cp /userapps/certs/live/zocate.li/fullchain.pem /userapps/ssl/zocate.li.pem
cp /userapps/certs/live/zocate.li/privkey.pem /userapps/ssl/zocate.li.key
```
- Reinicie o nginx

```bash
podman exec -it nginx nginx -s reload
```
