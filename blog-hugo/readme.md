### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/hugo
```

Tag version:
```
exts-0.147.0
```

Local para o dockerfile:
```
containers/blog-hugo
```

Imagem argumentos:
```
  
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  
```


### Documentação para uso da imagem

Container com **Hugo Extended** para geração de sites estáticos.
Utilizado no blog [zocate.li](https://zocate.li) com o tema PaperMod.

Imagem base: [hugomods/hugo](https://hub.docker.com/r/hugomods/hugo)

Executar em desenvolvimento:
```bash
docker compose up hugo
```

Executar build estático (produção):
```bash
docker run --rm -v $(pwd):/src lzocateli/hugo:exts-0.147.0 hugo --minify
```

#### Portas

| Porta | Descrição                        |
| ----- | -------------------------------- |
| 1313  | Hugo dev server (live reload)    |

#### Volumes

| Container Path | Descrição               |
| -------------- | ----------------------- |
| /src           | Raiz do projeto Hugo    |

#### Variáveis de Ambiente

| Variável | Padrão             | Descrição       |
| -------- | ------------------ | --------------- |
| TZ       | America/Sao_Paulo  | Timezone        |
