### Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
lzocateli/listmonk
```

Tag version:
```
v6.0.0
```

Local para o dockerfile:
```
containers/blog-listmonk
```

Imagem argumentos:
```
  
```

Baypass proxy: (insira 2 espaços a esquerda para não utilizar)
```
  
```


### Documentação para uso da imagem

Container **Listmonk** — plataforma de newsletter e mailing lists para o blog [zocate.li](https://zocate.li).
Utiliza imagem oficial do [Listmonk](https://listmonk.app/).

Depende do container **blog-postgres** estar saudável antes de iniciar.

Executar com docker-compose:
```bash
docker compose up -d listmonk
```

Acesso ao painel admin: http://localhost:9000

Credenciais padrão (dev):
- Usuário: `admin`
- Senha: `listmonk-dev-123`

#### Portas

| Porta | Descrição                |
| ----- | ------------------------ |
| 9000  | Interface web Listmonk   |

#### Variáveis de Ambiente

| Variável | Padrão            | Descrição       |
| -------- | ----------------- | --------------- |
| TZ       | America/Sao_Paulo | Timezone        |

A configuração principal é feita via arquivo `config.toml` montado como volume/config.

#### Configuração (config.toml)

```toml
[app]
address = "0.0.0.0:9000"
admin_username = "admin"
admin_password = "ALTERAR_EM_PRODUCAO"

[db]
host = "blog-postgres"
port = 5432
user = "blogadmin"
password = "ALTERAR_EM_PRODUCAO"
database = "listmonk"
ssl_mode = "disable"
max_open = 25
max_idle = 25
max_lifetime = "300s"
```

#### Dependências

- **blog-postgres** — database `listmonk` (criado pelo `init-db.sql`)

#### Comando de inicialização

Na primeira execução, o Listmonk precisa instalar o schema no banco:
```bash
./listmonk --install --idempotent --yes --config /listmonk/config.toml && ./listmonk --config /listmonk/config.toml
```

#### Produção

Em produção, o Listmonk é acessado via Nginx reverse proxy em `https://newsletter.zocate.li`.
O Quadlet de referência está em `deploy/containers/blog-listmonk.container`.

#### Integração com Hugo

O shortcode de newsletter está em `layouts/shortcodes/newsletter.html`.
Configuração em `hugo.toml`:
```toml
[params.newsletter]
  enabled = true
  listmonkURL = "https://newsletter.zocate.li"
  listUUID = ""  # Preencher após setup
```
