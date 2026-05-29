ARG UBUNTU_VERSION=22.04 # build variable (default value)
FROM ubuntu:$UBUNTU_VERSION

ARG DUMMY_VERSION=123
RUN echo "Dummy version is $DUMMY_VERSION"

ADD entrypoint.sh /entrypoint.sh
RUN chmod a+x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
