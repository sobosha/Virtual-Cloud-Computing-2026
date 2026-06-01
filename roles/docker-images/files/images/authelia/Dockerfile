ARG VERSION=4.39.14
FROM authelia/authelia:${VERSION}

# We add a new entrypoint and use it to replace the original one
COPY ./entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
ENTRYPOINT [ "/entrypoint.sh" ]