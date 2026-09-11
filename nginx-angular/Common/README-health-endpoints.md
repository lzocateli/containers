# 📋 Health Check Endpoints - Guia de Uso

## 📁 Arquivos Disponíveis

Este diretório contém **3 arquivos** de configuração de health check:

| Arquivo                        | Uso                      | Servidor          |
| ------------------------------ | ------------------------ | ----------------- |
| `004health-endpoints.conf`     | 📖 **Referência/Exemplo** | Consulta apenas   |
| `004health-endpoints-lb.conf`  | 🟢 **Load Balancer**      | Apenas LB         |
| `004health-endpoints-web.conf` | 🔵 **WebServer/Proxy**    | Apenas WebServers |

---

## 🎯 Qual arquivo usar?

### 🟢 Load Balancer
**Use:** `004health-endpoints-lb.conf`

**Características:**
- ✅ Health check agregado via `health-server` (porta 8090)
- ✅ Endpoint `/health` com status de todos os backends
- ✅ Endpoint `/nginx-health` para status do próprio LB
- ✅ Endpoints `/ping` e `/nginx-status`
- ⚠️ **Requer** `health-server.sh` rodando

**Destino:**
```bash
/etc/nginx/conf.d/004health-endpoints-lb.conf
```

---

### 🔵 WebServer / Proxy Reverso
**Use:** `004health-endpoints-web.conf`

**Características:**
- ✅ Endpoint `/nginx-health` para status do WebServer
- ✅ Endpoint `/ping` para checks rápidos
- ✅ Endpoint `/nginx-status` para métricas
- ✅ Opção de validar container backend via `/health`
- ❌ **NÃO requer** `health-server.sh`

**Destino:**
```bash
/etc/nginx/conf.d/004health-endpoints-web.conf
```

---

### 📖 Arquivo de Referência (Antigo)
**Arquivo:** `004health-endpoints.conf`

**Status:** ⚠️ Mantido para referência e compatibilidade

**Uso:**
- Consultar exemplos
- Entender diferenças entre LB e WebServer
- Migração de configurações antigas

**Recomendação:** Use os arquivos especializados (`-lb` ou `-web`)

---

## 📊 Comparação de Endpoints

| Endpoint        | Load Balancer     | WebServer          | Descrição       |
| --------------- | ----------------- | ------------------ | --------------- |
| `/health`       | ✅ Agregado (8090) | ✅ Container check  | Status completo |
| `/nginx-health` | ✅ Status LB       | ✅ Status WebServer | Status NGINX    |
| `/ping`         | ✅                 | ✅                  | Check rápido    |
| `/nginx-status` | ✅                 | ✅                  | Métricas        |

---

## 🚀 Instalação Rápida

### Load Balancer

```bash
# 1. Copiar configuração
sudo cp 004health-endpoints-lb.conf /etc/nginx/conf.d/

# 2. Iniciar health-server
systemctl --user enable health-server
systemctl --user start health-server

# 3. Testar sintaxe e recarregar
sudo nginx -t && sudo nginx -s reload

# 4. Validar
curl http://localhost:8090/health | jq
curl https://loadbalancer/health | jq
curl https://loadbalancer/nginx-health | jq
```

### WebServer

```bash
# 1. Copiar configuração
sudo cp 004health-endpoints-web.conf /etc/nginx/conf.d/

# 2. Testar sintaxe e recarregar
sudo nginx -t && sudo nginx -s reload

# 3. Validar
curl http://webserver/nginx-health | jq
curl http://webserver/ping
```

---

## 🔧 Integração

### Load Balancer - proxy-loadbalancer-prd.conf

```nginx
# Upstream para health-server
upstream health_server {
    server localhost:8090;
}

server {
    listen 443 ssl http2;
    server_name loadbalancer.example.com;

    # Health endpoints (copiar do arquivo -lb.conf)
    location /health {
        proxy_pass http://health_server/health;
        proxy_connect_timeout 2s;
        access_log off;
    }

    location /nginx-health {
        return 200 '{"status":"ok","service":"nginx-lb"}';
        add_header Content-Type application/json;
    }

    # Aplicações
    location / {
        proxy_pass http://webservers_upstream;
    }
}
```

### WebServer - proxy-webserver-prd.conf

```nginx
server {
    listen 80;
    server_name _;

    # Health endpoints (copiar do arquivo -web.conf)
    location /nginx-health {
        return 200 '{"status":"ok","service":"nginx-webserver"}';
        add_header Content-Type application/json;
    }

    location /ping {
        return 200 "pong\n";
        add_header Content-Type text/plain;
    }

    # Aplicações (proxy para containers)
    location /api {
        proxy_pass http://ApiContainer:5000;
    }
}
```

---

## ⚠️ Diferenças Críticas

### ❌ NÃO faça no WebServer:
```nginx
# ERRADO - WebServer não tem health-server
upstream health_server {
    server localhost:8090;  # ❌ health-server não roda no WebServer
}

location /health {
    proxy_pass http://health_server/health;  # ❌ Vai dar 502
}
```

### ✅ Correto no WebServer:
```nginx
# CORRETO - Health simples ou com backend check
location /nginx-health {
    return 200 '{"status":"ok"}';  # ✅ Simples e funcional
}

# OU validar container backend
location /health {
    proxy_pass http://MainApi:5000/health;  # ✅ Verifica container
}
```

---

## 🔍 Troubleshooting

### Load Balancer: 502 em /health
```bash
# Verificar health-server
systemctl --user status health-server
curl http://localhost:8090/health

# Se não estiver rodando
systemctl --user start health-server
```

### WebServer: 404 nos endpoints
```bash
# Verificar se locations estão dentro de server { }
sudo nginx -T | grep -A 10 "location /nginx-health"

# Locations devem estar DENTRO de server { ... }
```

### Load Balancer marca WebServer como down
```bash
# Testar do Load Balancer
curl http://webserver-ip/nginx-health

# Verificar logs
tail -f /var/log/nginx/error.log
```

---

## 📈 Monitoramento

### Verificar status de toda a infraestrutura

```bash
# Do Load Balancer - Status agregado de todos os backends
curl https://loadbalancer/health | jq

# Cada WebServer individualmente
curl http://webserver-01/nginx-health | jq
curl http://webserver-02/nginx-health | jq

# Métricas NGINX (Prometheus)
curl http://localhost/nginx-status
```

### Resposta esperada - Load Balancer `/health`:
```json
{
  "status": "healthy",
  "timestamp": "2026-02-07T19:30:00Z",
  "backends": {
    "webserver1": {"status": "up", "response_time": "0.023s"},
    "webserver2": {"status": "up", "response_time": "0.019s"}
  }
}
```

### Resposta esperada - WebServer `/nginx-health`:
```json
{
  "status": "ok",
  "service": "nginx-webserver",
  "host": "webserver-01",
  "timestamp": "2026-02-07T19:30:00Z"
}
```

---

## 📚 Arquivos Relacionados

- `health-server.sh` - Service para health check agregado (Load Balancer)
- `health-server.service` - Systemd unit para health-server
- `proxy-loadbalancer-prd.conf` - Configuração principal do Load Balancer
- `proxy-webserver-prd.conf` - Configuração principal do WebServer

---

## 🆕 Migração do arquivo antigo

Se você está usando `004health-endpoints.conf` (arquivo antigo):

1. **Identifique seu servidor:**
   - Load Balancer? → Use `004health-endpoints-lb.conf`
   - WebServer? → Use `004health-endpoints-web.conf`

2. **Copie o arquivo apropriado**

3. **Remova referências ao arquivo antigo:**
   ```bash
   sudo rm /etc/nginx/conf.d/004health-endpoints.conf
   ```

4. **Teste e recarregue:**
   ```bash
   sudo nginx -t && sudo nginx -s reload
   ```

---

## ✅ Checklist de Implementação

### Load Balancer
- [ ] Copiar `004health-endpoints-lb.conf` para `/etc/nginx/conf.d/`
- [ ] Adicionar upstream `health_server` no nginx.conf
- [ ] Copiar locations necessárias para `server { ... }`
- [ ] Verificar `health-server.sh` está rodando (porta 8090)
- [ ] Testar sintaxe: `sudo nginx -t`
- [ ] Recarregar: `sudo nginx -s reload`
- [ ] Validar: `curl https://loadbalancer/health | jq`

### WebServer
- [ ] Copiar `004health-endpoints-web.conf` para `/etc/nginx/conf.d/`
- [ ] Copiar locations necessárias para `server { ... }`
- [ ] Testar sintaxe: `sudo nginx -t`
- [ ] Recarregar: `sudo nginx -s reload`
- [ ] Validar: `curl http://webserver/nginx-health | jq`
- [ ] Testar do Load Balancer: `curl http://webserver-ip/nginx-health`

---

**Criado em:** 2026-02-07  
**Versão:** 2.0 (Arquivos separados LB/WebServer)
