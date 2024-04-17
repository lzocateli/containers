FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Sao_Paulo

RUN apt-get update

RUN apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release

RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg

RUN echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null

RUN apt-get update
RUN apt-get install -y docker-ce docker-ce-cli containerd.io openssl
RUN . /etc/os-release && apt install -y -t ${VERSION_CODENAME}-backports cockpit cockpit-podman 
# RUN apt-get install -y cockpit cockpit-podman 
RUN /usr/lib/cockpit/cockpit-certificate-ensure
RUN /usr/lib/cockpit/cockpit-certificate-ensure --check
# RUN openssl req -x509 -nodes -days 5480 -newkey rsa:2048 \
#   -keyout /etc/cockpit/ws-certs.d/cockpit.key \
#   -out /etc/cockpit/ws-certs.d/cockpit.pem \
#   -subj "/C=US/ST=Denial/L=Springfield/O=Dis/CN=localhost" \
#   -keyform PEM -outform PEM

EXPOSE 9090

CMD ["/usr/lib/cockpit/cockpit-ws"]
