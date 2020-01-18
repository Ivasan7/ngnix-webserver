FROM ubuntu:18.04

RUN apt-get -y update &&  apt-get -y upgrade
RUN  apt-get install -y \
	vim \
	curl \
	lsb-core \
	gnupg \
	systemd

#Install NGNIX

RUN echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key |  apt-key add - && \
    apt-key fingerprint ABF5BD827BD9BF62 && \
    apt update && apt install nginx

RUN systemctl enable nginx 

COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh
RUN ln -s /usr/local/bin/start.sh

ENTRYPOINT["start.sh"]
