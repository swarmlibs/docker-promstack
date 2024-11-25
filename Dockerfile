FROM docker:27-cli
RUN apk add --no-cache bash curl jq
ADD rootfs /
RUN chmod +x /usr/bin/promstack /docker-entrypoint.d/*.sh
CMD [ "/usr/bin/promstack" ]
