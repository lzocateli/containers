# Dockerfile customizado para Comentario
# Baseado na imagem oficial, configurado para aceitar variáveis de ambiente
# Build: docker build -f Dockerfile.comentario -t lzocateli/comentario:v3.16.0 .

FROM registry.gitlab.com/comentario/comentario:v3.16.0

# Metadata
LABEL maintainer="Lincoln Zocateli"
LABEL version="3.16.0"
LABEL description="Comentario customizado - aceita configuração via ENV vars"

# Variáveis de ambiente com valores padrão (podem ser sobrescritas no docker-compose.yml)
# Nota: SECRET_KEY e SMTP_PASSWORD devem ser passados em tempo de execução via docker-compose ou docker run
ENV BASE_URL="http://localhost:8080" \
  SMTP_HOST="" \
  SMTP_PORT="587" \
  SMTP_USERNAME="" \
  SMTP_FROM="" \
  TZ="America/Sao_Paulo"

ENV TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Porta padrão do Comentario
EXPOSE 80

# Healthcheck para verificar se o serviço está respondendo
HEALTHCHECK --interval=30s --timeout=10s --start-period=40s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:80/api/health || exit 1

# Comando de inicialização (herdado da imagem base)
# A imagem oficial já aceita ENV vars, então não precisa de script adicional
