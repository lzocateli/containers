## Para executar o container

```bash
#!/bin/bash

podman rm redis -f

podman run -d \
  -q \
  -p 6379:6379 \
  -e TZ=America/Sao_Paulo \
  -v /userapps/tmp/redis:/tmp:Z \
  -v /userapps/configs/redis/etc/sysctl.conf:/etc/sysctl.conf \
  -v /userapps/configs/redis/etc/redis.conf:/usr/local/etc/redis/redis.conf \
  -v /userapps/var/log/redis/redis.log:/data/redis.log \
  --restart always \
  --network=cbl \
  --name redis \
  --health-cmd "redis-cli ping" \
  --health-interval 60s \
  --health-retries 3 \
  lzocateli/redis:7.4.0-bookworm \
  redis-server /usr/local/etc/redis/redis.conf


sleep 10
podman ps -a
podman logs redis
cat /userapps/var/log/redis/redis.log
```
