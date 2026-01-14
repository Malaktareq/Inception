From debian:bookworm-slim

RUN apt update -y \
    && apt install nginx -y

COPY tools/nginx.sh .

RUN chmod +x nginx.sh


CMD ["nginx", "-g", "daemon off;"]
