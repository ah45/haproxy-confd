FROM ubuntu:14.04
MAINTAINER Adam Harper <docker@adam-harper.com>

# install current backport of haproxy
RUN \
  sed -i 's/^# \(.*-backports\s\)/\1/g' /etc/apt/sources.list && \
  apt-get update && \
  apt-get install -y wget haproxy=1.5.3-1~ubuntu14.04.1 && \
  sed -i 's/^ENABLED=.*/ENABLED=1/' /etc/default/haproxy && \
  rm -rf /var/lib/apt/lists/*

# install a dummy wildcard certificate
RUN \
   openssl req -new -x509 \
   -keyout "/etc/ssl/private/*.example.com.pem" \
   -out "/etc/ssl/private/*.example.com.pem" \
   -days 365 -nodes \
   -subj "/C=US/ST=private/L=province/O=city/CN=*.example.com"

# install confd to dynamically write configuration
RUN \
  wget -O /usr/local/bin/confd \
  https://github.com/kelseyhightower/confd/releases/download/v0.6.0-alpha3/confd-0.6.0-alpha3-linux-amd64 && \
  chmod +x /usr/local/bin/confd && \
  mkdir -p /etc/confd

# copy the default configuration
ADD resources/confd /etc/confd

# add our scripts
ADD build-config /build-config
ADD start /start

RUN chmod +x /build-config /start

# define a mount point for configuration overrides
VOLUME ["/confd-override"]
# and another for ssl certs
VOLUME ["/etc/ssl/private"]

# expose default web ports
EXPOSE 80
EXPOSE 443

ENTRYPOINT ["/start"]
