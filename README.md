# Postfix relay running in Kubernetes

This repository has an example of a postfix relay running in Kubernetes using a helm chart.
## Build Docker image

You can build the Docker image locally

```bash
docker build -t eldada-docker-examples.bintray.io/postfix-relay:0.6 Docker/
```

## Run locally with Docker

Run the postfix relay locally for testing

```bash
# Need to set SMTP connection details
export SMTP="[smtp.mailgun.org]:587"
export USERNAME=<your smtp username>
export PASSWORD=<your smtp password>

# Optional custom configuration to add/override in /etc/postfix/main.cf (delimited by a ";")
export POSTFIX_CUSTOM_CONFIG="key1 = value1;key2 = value2;key3 = value3"

# Set list of allowed networks
export TX_SMTP_RELAY_NETWORKS='10.0.0.0/8,127.0.0.0/8,172.17.0.0/16,192.0.0.0/8'

docker run --rm -d --name postfix-relay -p 2525:25 \
	-e TX_SMTP_RELAY_HOST="${SMTP}" \
	-e TX_SMTP_RELAY_MYHOSTNAME=my.local \
	-e TX_SMTP_RELAY_USERNAME=${USERNAME} \
	-e TX_SMTP_RELAY_PASSWORD=${PASSWORD} \
	-e TX_SMTP_RELAY_NETWORKS=${TX_SMTP_RELAY_NETWORKS} \
	-e POSTFIX_CUSTOM_CONFIG="${POSTFIX_CUSTOM_CONFIG}" \
	eldada-docker-examples.bintray.io/postfix-relay:0.6
```

### Test sending mail

1. Connect to running container on port 2525

```bash
telnet localhost 2525
```

1. Edit the following with your details and paste in your terminal

```bash
helo localhost
mail from: noreply@yourhost.com
rcpt to: you@your.co
data
Subject: Subject here...
The true story of swans singing Pink Floyd. 
.
quit
```

1. You should see the following:

```bash
220 tx-smtp-relay.yourhost.com ESMTP Postfix
helo localhost
250 tx-smtp-relay.yourhost.com
mail from: noreply@yourhost.com
250 2.1.0 Ok
rcpt to: you@your.co
250 2.1.5 Ok
data
354 End data with <CR><LF>.<CR><LF>
Subject: Subject here...
The true story of swans singing Pink Floyd. 
.
250 2.0.0 Ok: queued as 982FF53C
quit
221 2.0.0 Bye
Connection closed by foreign host
```
4. Check the inbox of `you@your.co` and see you got the email.

## Deploy Helm Chart

The Helm Chart in [helm/postfix](helm/postfix) directory can be used to deploy the postfix-relay into your Kubernetes cluster.

The Chart will deploy 2 pods (for high availability), load balanced with a service, exposing port 25.

```bash
# Need to set SMTP connection details
export SMTP="[smtp.mailgun.org]:587"
export USERNAME=<your smtp username>
export PASSWORD=<your smtp password>

helm upgrade --install postfix-relay \
        --set smtp.relayHost=${SMTP} \
        --set smtp.relayMyhostname=my.local \
        --set smtp.relayUsername=${USERNAME} \
        --set smtp.relayPassword=${PASSWORD} \ 
        helm/postfix

```

## Chart Options for Managing Secrets

1. Use existing secret:

Use Other options such as [kubernetes external secrets](https://github.com/external-secrets/kubernetes-external-secrets) (see below) or [sealedSecrets](https://github.com/bitnami-labs/sealed-secrets)
create the smtp password kubernetes secret then just reference it.

```bash
helm upgrade --install postfix-relay \
        --set smtp.relayHost=${SMTP} \
        --set smtp.relayMyhostname=my.local \
        --set smtp.relayUsername=${USERNAME} \
        --set smtp.relayPassword=${PASSWORD} \ 
        --set useExistingSecret=true \
        --set existingSecretName=postfix \
        helm/postfix
```

1. Use kubernetes external secrets

- have the chart generate the smtp-password from `externalSecrets` in this case you should update your backend secret to have the required key named `tx-smtp-relay-password` with your SMTP password so it can be set into the postfix config at runtime.

```bash
helm upgrade --install postfix-relay \
        --set smtp.relayHost=${SMTP} \
        --set smtp.relayMyhostname=my.local \
        --set smtp.relayUsername=${USERNAME} \
        --set useExternalSecrets=true \
        --set ExternalSecretsBackendType=secretsManager \
        --set ExternalSecretsKey=infra/postfix \
        helm/postfix
```

## Thanks

This work is based on examples from https://github.com/applariat/kubernetes-postfix-relay-host 
