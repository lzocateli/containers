### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/comentario
```

Tag version:
```
v3.16.0
```

Local para o dockerfile:
```
containers/blog-comentario
```

Imagem argumentos:
```
  
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  
```


### Documentação para uso da imagem

Container **Comentario** — sistema de comentários open source para o blog [zocate.li](https://zocate.li).
Utiliza imagem oficial do [Comentario](https://comentario.app/).

Depende do container **blog-postgres** estar saudável antes de iniciar.

Executar com docker-compose:
```bash
docker compose up -d comentario
```

#### Portas

| Porta | Descrição                 |
| ----- | ------------------------- |
| 80    | Interface web Comentario  |

#### Variáveis de Ambiente

| Variável            | Padrão                          | Descrição                              |
| ------------------- | ------------------------------- | -------------------------------------- |
| BASE_URL            | http://localhost:8080            | URL pública do Comentario              |
| POSTGRES_DATASOURCE | postgres://blogadmin:...@postgres:5432/comentario?sslmode=disable | Connection string PostgreSQL |
| SECRET_KEY          | (obrigatório em produção)       | Chave secreta para tokens              |
| SMTP_ENABLED        | false                           | Habilitar envio de e-mails             |

#### Dependências

- **blog-postgres** — database `comentario` (criado pelo `init-db.sql`)

#### Produção

Em produção, o Comentario é acessado via Nginx reverse proxy em `https://comentarios.zocate.li`.
O Quadlet de referência está em `deploy/containers/blog-comentario.container`.

#### Integração com Hugo

O tema PaperMod inclui o widget de comentários via partial em `layouts/partials/comments.html`.
Configuração em `hugo.toml`:
```toml
[params.comentario]
  enabled = true
  serverURL = "https://comentarios.zocate.li"
```
