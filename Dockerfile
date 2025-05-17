FROM alpine:latest

RUN apk add --no-cache bash curl jq

WORKDIR /app
COPY porkbun-dns-updater-new.sh .

RUN chmod +x porkbun-dns-updater-new.sh

ENTRYPOINT ["./porkbun-dns-updater-new.sh"]
