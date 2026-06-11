ARG VERSION=4.39.14
FROM authelia/authelia:${VERSION}

# TODO[VCC-005]: Add a new entrypoint for authelia and use it to replace the original
COPY ./entrypoint.sh /entrypoint.sh
# Normalize entrypoint.sh line endings from Windows CRLF to Unix LF,
# then make the script executable so it can run correctly in the container.
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]