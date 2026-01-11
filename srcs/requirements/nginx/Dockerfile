From debian:bookworm-slim

RUN apt-get update \
    && apt-get install nginx

COPY tools/nginx.sh .

RUN chmod +x ./tools/nginx.sh

CMD ["./tools/nginx.sh"]