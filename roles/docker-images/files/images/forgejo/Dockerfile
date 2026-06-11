ARG VERSION=11.0.8
FROM codeberg.org/forgejo/forgejo:${VERSION}

# Install postgresql-client to provide the 'psql' command, which is used
# in entrypoint.sh to verify the database is alive before starting Forgejo.
# The base Forgejo Alpine image does not include it by default.
USER root
RUN apk add --no-cache postgresql-client sudo
COPY ./entrypoint.sh /entrypoint.sh
# Normalize entrypoint.sh line endings from Windows CRLF to Unix LF,
# then make the script executable so it can run correctly in the container.
# bug -> Mv original entrypoint to a new file and run original entripoint after running the my entrypoint 
RUN sed -i 's/\r$//' /entrypoint.sh && chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]