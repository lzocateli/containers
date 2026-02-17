ARG BUILDPLATFORM=linux/amd64

FROM --platform=$BUILDPLATFORM python:3.12-bookworm

RUN apt update -y && apt upgrade -y \
 && apt install -y sudo sshpass aha less gpg jq wget lsb-release curl unzip python3-pip

RUN wget -O- https://apt.releases.hashicorp.com/gpg | gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg \
 && echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | tee /etc/apt/sources.list.d/hashicorp.list \
 && apt update -y && apt install -y terraform

RUN curl -sL https://aka.ms/InstallAzureCLIDeb | bash
 
RUN pip install --upgrade pip
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
 
# Instale o Ansible usando pip
RUN apt-get install -y ssh
RUN pip install ansible ansible-dev-tools passlib


ARG TZ=America/Sao_Paulo
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone

RUN apt install -y zsh
# zsh-autosuggestions
# RUN echo "plugins=(zsh-autosuggestions)" >> ~/.zshrc \
# && echo 'HISTFILE=~/.zsh_history' >> ~/.zshrc


RUN sh -c "$(curl -fsSL https://ohmyposh.dev/install.sh)"



#RUN sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Instale o plugin zsh-autosuggestions
RUN git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Adicione o plugin ao arquivo de configuração .zshrc
RUN echo "plugins=(zsh-autosuggestions)" >> ~/.zshrc \
 && echo 'HISTFILE=~/.histfile' >> ~/.zshrc
