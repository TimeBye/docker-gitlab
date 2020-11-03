FROM ubuntu:bionic-20200921

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION=11.6.11

ENV GITLAB_VERSION=${VERSION} \
    RUBY_VERSION=2.5 \
    GOLANG_VERSION=1.11.4 \
    GITLAB_SHELL_VERSION=8.4.3 \
    GITLAB_WORKHORSE_VERSION=7.6.0 \
    GITLAB_PAGES_VERSION=1.3.1 \
    GITALY_SERVER_VERSION=1.7.1 \
    GITLAB_USER="git" \
    GITLAB_HOME="/home/git" \
    GITLAB_LOG_DIR="/var/log/gitlab" \
    GITLAB_CACHE_DIR="/etc/docker-gitlab" \
    RAILS_ENV=production \
    NODE_ENV=production

ENV GITLAB_INSTALL_DIR="${GITLAB_HOME}/gitlab" \
    GITLAB_SHELL_INSTALL_DIR="${GITLAB_HOME}/gitlab-shell" \
    GITLAB_GITALY_INSTALL_DIR="${GITLAB_HOME}/gitaly" \
    GITLAB_DATA_DIR="${GITLAB_HOME}/data" \
    GITLAB_BUILD_DIR="${GITLAB_CACHE_DIR}/build" \
    GITLAB_RUNTIME_DIR="${GITLAB_CACHE_DIR}/runtime"

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      wget ca-certificates apt-transport-https gnupg2
RUN set -ex && \
 apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv E1DD270288B4E6030699E45FA1715D88E1DF1F24 \
 && echo "deb http://ppa.launchpad.net/git-core/ppa/ubuntu bionic main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 80F70E11F0F0D5F10CB20E62F5DA5F09C3173AA6 \
 && echo "deb http://ppa.launchpad.net/brightbox/ruby-ng/ubuntu bionic main" >> /etc/apt/sources.list \
 && apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv 8B3981E7A6852F782CC4951600A6F0A3C300EE8C \
 && echo "deb http://ppa.launchpad.net/nginx/stable/ubuntu bionic main" >> /etc/apt/sources.list \
 && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - \
 && echo 'deb http://apt.postgresql.org/pub/repos/apt/ bionic-pgdg main' > /etc/apt/sources.list.d/pgdg.list \
 && wget --quiet -O - https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add - \
 && echo 'deb https://deb.nodesource.com/node_8.x bionic main' > /etc/apt/sources.list.d/nodesource.list \
 && wget --quiet -O - https://dl.yarnpkg.com/debian/pubkey.gpg  | apt-key add - \
 && echo 'deb https://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list \
 && set -ex \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install --no-install-recommends -y \
      sudo supervisor logrotate locales curl \
      nginx openssh-server mysql-client postgresql-client-12 postgresql-contrib-12 redis-tools \
      git-core ruby${RUBY_VERSION} python3 python3-docutils nodejs yarn gettext-base graphicsmagick \
      libpq5 zlib1g libyaml-0-2 libssl1.0.0 \
      libgdbm5 libreadline7 libncurses5 libffi6 \
      libxml2 libxslt1.1 libcurl4 libicu60 libre2-dev tzdata unzip libimage-exiftool-perl \
 && update-locale LANG=C.UTF-8 LC_MESSAGES=POSIX \
 && locale-gen en_US.UTF-8 \
 && DEBIAN_FRONTEND=noninteractive dpkg-reconfigure locales; \
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"; \
	case "${dpkgArch}" in \
		arm64) \
            update-alternatives --install /usr/bin/erb  erb  /usr/bin/erb${RUBY_VERSION}  1; \
            update-alternatives --install /usr/bin/gem  gem  /usr/bin/gem${RUBY_VERSION}  1; \
            update-alternatives --install /usr/bin/irb  irb  /usr/bin/irb${RUBY_VERSION}  1; \
            update-alternatives --install /usr/bin/rdoc rdoc /usr/bin/rdoc${RUBY_VERSION} 1; \
            update-alternatives --install /usr/bin/ri   ri   /usr/bin/ri${RUBY_VERSION}   1; \
            update-alternatives --install /usr/bin/ruby ruby /usr/bin/ruby${RUBY_VERSION} 1; \
            ;; \
	esac; \
#  && gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ \
#  && gem sources -l \
    gem install --no-document bundler -v 1.17.3 \
 && rm -rf /var/lib/apt/lists/*

COPY assets/build/ ${GITLAB_BUILD_DIR}/
RUN bash ${GITLAB_BUILD_DIR}/install.sh

COPY setzero/customize_oauth.rb ${GITLAB_INSTALL_DIR}/config/initializers/
COPY assets/runtime/ ${GITLAB_RUNTIME_DIR}/
COPY entrypoint.sh /sbin/entrypoint.sh
RUN chmod 755 /sbin/entrypoint.sh && \
    sed -i 's/create_table.*/create_table :lfs_file_locks, options: '"'ROW_FORMAT=DYNAMIC'"' do |t|/' ${GITLAB_INSTALL_DIR}/db/migrate/20180116193854_create_lfs_file_locks.rb && \
    sed -i 's/t.string :query/t.text :query/' ${GITLAB_INSTALL_DIR}/db/migrate/20180101160629_create_prometheus_metrics.rb && \
    sed -i 's/t.string "query"/t.text "query"/' ${GITLAB_INSTALL_DIR}/db/schema.rb

LABEL \
    maintainer="sameer@damagehead.com" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date=${BUILD_DATE} \
    org.label-schema.name=gitlab \
    org.label-schema.vendor=damagehead \
    org.label-schema.url="https://github.com/sameersbn/docker-gitlab" \
    org.label-schema.vcs-url="https://github.com/sameersbn/docker-gitlab.git" \
    org.label-schema.vcs-ref=${VCS_REF} \
    com.damagehead.gitlab.license=MIT

EXPOSE 22/tcp 80/tcp 443/tcp

VOLUME ["${GITLAB_DATA_DIR}", "${GITLAB_LOG_DIR}"]
WORKDIR ${GITLAB_INSTALL_DIR}
ENTRYPOINT ["/sbin/entrypoint.sh"]
CMD ["app:start"]
