FROM nginx:alpine as base

FROM base as builder

ARG JWT_MODULE_PATH=/usr/local/lib/ngx-http-auth-jwt-module

RUN mkdir -p $JWT_MODULE_PATH/src

RUN apk add --no-cache gcc libc-dev make openssl-dev pcre-dev zlib-dev \
  linux-headers curl gnupg libxslt-dev gd-dev jansson-dev autoconf \
  automake libtool cmake check-dev \
  -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libjwt-dev

# NGINX_VERSION is a variable available within the nginx:alpine Docker image
RUN curl -fSL http://nginx.org/download/nginx-${NGINX_VERSION}.tar.gz -o nginx.tar.gz \
  && mkdir -p /usr/src \
  && tar -zxC /usr/src -f nginx.tar.gz \
  && rm nginx.tar.gz

ADD config $JWT_MODULE_PATH/config
ADD src $JWT_MODULE_PATH/src

RUN cd /usr/src/nginx-${NGINX_VERSION} \
  && ./configure --with-compat --add-dynamic-module=$JWT_MODULE_PATH \
  && make modules

FROM nginx:alpine

COPY --from=builder /usr/src/nginx-${NGINX_VERSION}/objs/ngx_http_auth_jwt_module.so /usr/lib/nginx/modules/ngx_http_auth_jwt_module.so

RUN apk add --no-cache jansson \
  -X http://dl-cdn.alpinelinux.org/alpine/edge/testing libjwt \
  && sed -i '1iload_module modules/ngx_http_auth_jwt_module.so;' /etc/nginx/nginx.conf
