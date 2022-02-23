FROM ubuntu:20.04

# ubuntu em português br
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  && localedef -i pt_BR -c -f UTF-8 -A /usr/share/locale/locale.alias pt_BR.UTF-8
ENV LANG pt_BR.utf8
RUN update-locale LANG=pt_BR.UTF-8

# Configurando a time-zone do servidor
RUN timedatectl set-timezone America/Sao_Paulo
RUN /etc/init.d/cron restart && apt-get update && apt-get upgrade -y

RUN pt install build-essential checkinstall libreadline-gplv2-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y

# instalar o python
RUN cd /opt
RUN wget https://www.python.org/ftp/python/3.10.2/Python-3.10.2.tar.xz
RUN tar -xvf Python-3.10.0.tar.xz
RUN cd Python-3.10.2 && ./configure --enable-optimizations && make altinstall
RUN cd opt && rm Python-3.10.2.tar.xz

RUN apt-get install nginx gunicorn3 virtualenv python3-venv python3-dev git-core

#instalar certificado ssl
RUN add-apt-repository ppa:certbot/certbot
RUN apt-get install python-certbot-nginx letsencryp 
RUN ufw delete allow 'Nginx HTTP' && ufw allow ssh && ufw enable && ufw allow 'Nginx Full' && ufw delete allow 'Nginx HTTP'

#criar usuario
RUN useradd -ms /bin/bash tiago
USER tiago
RUN mkdir workspace

#Preparar ambiente
RUN cd /home/tiago/workspace && git clone https://github.com/tiagobfaustino/deployflask
WORKDIR /home/tiago/workspace/deployflask
ADD . .
RUN python3 -m venv venv
RUN source venv/bin/activate
RUN https://github.com/tiagobfaustino/deployflask
RUN pip install -r requirements.txt && deactivate

# configurar serviço
RUN sudo cp -i deployflask.service /etc/systemd/system/deployflask.service
RUN sudo systemctl daemon-reload
RUN sudo systemctl start deployflask && sudo systemctl enable deployflask
RUN sudo systemctl status deployflask

# Configurar nginx
RUN sudo cp -i deployflaskapp /etc/nginx/sites-enabled/deployflaskapp
RUN sudo service nginx restart
RUN sudo certbot --nginx -d analyst.tk -d analyst.tk

RUN cd /home/tiago/workspace/deployflask