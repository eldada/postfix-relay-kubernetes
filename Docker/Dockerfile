FROM alpine:3.17.2

MAINTAINER Eldad Assis <eldad.assis@gmail.com>

# Install postfix and supervisor
RUN apk add --no-cache \
    postfix \
    rsyslog \
	libsasl \
	cyrus-sasl-login \
	ca-certificates \
    supervisor && \
    /usr/bin/newaliases

# Copy files into container
COPY . /

# SMTP port
EXPOSE 25

ENTRYPOINT [ "/entrypoint.sh" ]
