FROM docker:27-cli
RUN apk add --no-cache bash curl jq
ADD rootfs /
RUN chmod +x /docker-entrypoint-shim.sh /promstack.sh
ENTRYPOINT [ "/docker-entrypoint-shim.sh" ]
CMD [ "/promstack.sh" ]
