## Para executar o container

```bash
#!/bin/bash

podman rm redis -f

podman run -d \
  -q \
  -e TZ=America/Sao_Paulo \
  -v /userapps/tmp/redis:/tmp:Z \
  -v /userapps/configs/redis/etc/sysctl.conf:/etc/sysctl.conf \
  -v /userapps/configs/redis/etc/redis.conf:/usr/local/etc/redis/redis.conf \
  -v /userapps/var/log/redis/redis.log:/data/redis.log \
  --restart always \
  --network=lzo \
  --name redis \
  lzocateli/redis:7.4.0-bookworm \
  redis-server /usr/local/etc/redis/redis.conf


sleep 10
podman ps -a
cat /userapps/var/log/redis/redis.log
```
