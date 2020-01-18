FROM ubuntu:18.04

RUN apt-get -y update &&  apt-get -y upgrade
RUN  apt-get install -y \
	vim \
	curl \
	lsb-core \
	gnupg \
	systemd \ 
	apache2-utils \
	git

#Install libraries for dynamic modules
RUN apt-get install -y \
	libgeoip-dev \
	libcurl4-openssl-dev \
	libxml2-dev \ 
	libxslt1-dev \
	libgd-dev \
	libdb-dev \
	libssl-dev \
	libghc-regex-pcre-dev \
	libb-utils-perl \
	libyajl-dev \
	zlib1g-dev

#Get modsecurity project

RUN cd /opt  && git clone --depth 1 -b v3/master https://github.com/SpiderLabs/ModSecurity
RUN cd ModSecurity && \
	git submodule init && \
	git submodule update && \
	./build.sh && \
	./configure && \
	make && \
	make install

#Install NGNIX

RUN echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key |  apt-key add - && \
    apt-key fingerprint ABF5BD827BD9BF62 && \
    apt update && apt install nginx


COPY start.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/start.sh
RUN ln -s /usr/local/bin/start.sh

#Self signed certificates
RUN mkdir -p /etc/nginx/ssl
RUN openssl req -x509 -nodes -days 365 \
	-newkey rsa:2048
	-keyout /etc/nginx/ssl/private.key \
	-out /etc/nginx/ssl/public.pem



#NGINX settings

COPY 404.html /usr/share/nginx/html/404.html
COPY default.conf /etc/nginx/conf.d/default.conf
# PWD generation : htpasswd -c /etc/nginx/.htpasswd admin
RUN service nginx reload


ENTRYPOINT["start.sh"]
