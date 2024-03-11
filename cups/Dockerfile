FROM debian:buster

RUN apt-get update \
    && apt-get install -y \
    sudo \
    whois \
    usbutils \
    cups \
    cups-client \
    cups-bsd \
    cups-filters \
    foomatic-db-compressed-ppds \
    printer-driver-all \
    openprinting-ppds \
    hpijs-ppds \
    hp-ppd \
    hplip \
    smbclient \
    printer-driver-cups-pdf \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd \
    --groups=sudo,lp,lpadmin \
    --create-home \
    --home-dir=/home/print \
    --shell=/bin/bash \
    --password=$(mkpasswd print) \
    print \
    && sed -i '/%sudo[[:space:]]/ s/ALL[[:space:]]*$/NOPASSWD:ALL/' /etc/sudoers

COPY --chown=root:lp cupsd.conf /etc/cups/cupsd.conf

CMD ["/usr/sbin/cupsd", "-f"]