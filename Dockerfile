FROM ubuntu:18.04

RUN apt-get -y update &&  apt-get -y upgrade
RUN  apt-get install -y \
	vim \
	curl \
	lsb-core \
	gnupg \
	systemd \ 
	apache2-utils \
	git \
	wget

RUN echo "deb http://nginx.org/packages/ubuntu `lsb_release -cs` nginx" \
    | tee /etc/apt/sources.list.d/nginx.list && \
    curl -fsSL https://nginx.org/keys/nginx_signing.key |  apt-key add - && \
    apt-key fingerprint ABF5BD827BD9BF62 && \
    apt update && apt install nginx

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

# Build Dynamic Module
RUN cd /opt && git clone --depth 1 https://github.com/SpiderLabs/ModSecurity-nginx.git && \
	b=$(nginx -v 2>&1) && VERSION=$(echo $b | grep -o -E '[0-9].+') && \
	wget http://nginx.org/download/nginx-${VERSION}.tar.gz && \
	tar zxvf nginx-${VERSION}.tar.gz && \
	cd nginx-${VERSION} && \
	./configure --with-compat --add-dynamic-module=../ModSecurity-nginx && \
	make modules && \
	cp objs/ngx_http_modsecurity_module.so /etc/nginx/modules/

#TODO
#Load at /etc/nginx/nginx.conf after PID
#load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;
RUN sed -i '/pid* /a #Load\nload_module /etc/nginx/modules/ngx_http_modsecurity_module.so;'  /etc/nginx/nginx.conf


COPY modsecurity.conf-recommended /etc/nginx/modsecurity/modsecurity.conf
COPY unicode.mapping /etc/nginx/modsecurity/unicode.mapping

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


RUN cd /etc/nginx/modsecurity && \
	git clone https://github.com/SpiderLabs/owasp-modsecurity-crs.git && \
	cd owasp-modsecurity-crs && \
	cp crs-setup.conf{.example,} && \
	cp rules/REQUEST-900-EXCLUSION-RULES-BEFORE-CRS.conf{.example,} && \
	cp rules/RESPONSE-999-EXCLUSION-RULES-AFTER-CRS.conf{.example,}

RUN cd /etc/nginx/modsecurity && \
	echo "include modsecurity.conf" >> modsecurity_includes.conf && \
	echo "include owasp-modsecurity-crs/crs-setup.conf" >> modsecurity_includes.conf && \
	for f in $(ls -1 owasp-modsecurity-crs/rules/ | grep -E "^(RESPONSE|REQUEST)-.*\.conf$"); do \
  	echo "include owasp-modsecurity-crs/rules/${f}" >> modsecurity_includes.conf; done





ENTRYPOINT["start.sh"]
