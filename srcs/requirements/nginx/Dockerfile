From debian:bookworm-slim

RUN apt update -y \
    && apt install nginx -y \
    && apt install openssl -y

COPY  conf/default.conf /etc/nginx/conf.d
RUN rm -f /etc/nginx/sites-enabled/default

#CMD ["nginx","-g","daemon off;"]
CMD ["tail", "-f"]
