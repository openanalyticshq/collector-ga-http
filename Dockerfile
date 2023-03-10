ARG PROCESSOR_SCHEME=http
ARG PROCESSOR_HOST=127.0.0.1
ARG PROCESSOR_PORT=11001

FROM openresty/openresty:alpine

WORKDIR /usr/local/openresty/nginx

COPY resty_modules ./
COPY conf ./
COPY lua ./

EXPOSE 10001
