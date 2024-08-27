
## Crie esse arquivo com usuario sudo
```bash
nano /etc/systemd/user/podman-compose@.service
```

- [x] Copie esse conteudo

```
# /etc/systemd/user/podman-compose@.service

[Unit]
Description=%i rootless pod (podman-compose)

[Service]
Type=simple
EnvironmentFile=%h/.config/containers/compose/projects/%i.env
ExecStartPre=-/home/brazildevops/.local/bin/podman-compose up --no-start
ExecStartPre=/usr/bin/podman pod start pod_%i
ExecStart=/home/brazildevops/.local/bin/podman-compose wait
ExecStop=/usr/bin/podman pod stop pod_%i

[Install]
WantedBy=default.target
```

- [x] Execute esse comando para habilitar o serviço, precisa estar logado como `brazildevops`

```bash
systemctl --user enable --now 'podman-compose@dns'

# Verifique o status
systemctl --user status podman-compose@dns
```
