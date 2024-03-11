## Overview
Docker image including CUPS print server and printing drivers (installed from the Debian packages).

- Informe os seguintes parametros para gerar a imagem

Nome da Imagem:
```
cups-2.2.10-buster
```

Tag version:
```
1.0.0
```

Local para o dockerfile:
```
containers/cups
```

Imagem argumentos:
```
--build-arg Env_HttpProxy=proxy.xyz.com:80 --build-arg Env_NoProxy=xyz.com
```

Baypass proxy:
```
xyz\.com
```

## Run the Cups server
Using the default [cupsd.conf](cupsd.conf) configuration file:
```bash
podman run -d \
-p 631:631 \
-v /var/run:/var/run/dbus \
--network=nuuvers \
--network-alias=cupsd \
--name cupsd \
lzocateli/cups-2.2.10-buster:1.0.0
```

Using a custom cupsd.conf configuration file:
```bash
podman run -d \
-p 631:631 \
-v /var/run:/var/run/dbus \
-v $PWD/cupsd.conf:/etc/cups/cupsd.conf \
--network=nuuvers \
--network-alias=cupsd \
--name cupsd \
lzocateli/cups-2.2.10-buster:1.0.0
```


## Add printers to the Cups server
1. Connect to the Cups server at [http://yourhost:631](http://yourhost:631)
2. Add printers: Administration > Printers > Add Printer

__Note__: The admin user/password for the Cups server is `print`/`print`

## Configure Cups client on your machine
1. Install the `cups-client` package
2. Edit the `/etc/cups/client.conf`, set `ServerName` to `yourhost:631`
3. Test the connectivity with the Cups server using `lpstat -r`
4. Test that printers are detected using `lpstat -v`
5. Applications on your machine should now detect the printers!
