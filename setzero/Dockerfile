FROM sameersbn/gitlab:18.5.7

RUN set -ex \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      fail2ban \
 && rm -rf /var/lib/apt/lists/*

COPY assets/runtime /etc/docker-gitlab/runtime