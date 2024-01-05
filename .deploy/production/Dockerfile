ARG RUBY_VERSION=3.1.2
ARG TAILSCALE_VERSEION=1.14.0

# FROM ruby:${RUBY_VERSION}-alpine
# RUN apk update && apk add --no-cache \
#     alpine-sdk build-base gcompat \
#     postgresql-dev postgresql-client \
#     # sqlite-dev mysql-client \
#     vim nano bash \
#     git wget curl nodejs \
#     sudo dumb-init shadow tzdata \
#    && rm -rf /var/cache/apk/*

FROM ruby:${RUBY_VERSION}
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential libmsgpack-dev \
    libpq-dev postgresql postgresql-contrib \
    sqlite3 libsqlite3-dev default-mysql-server \
    vim nano bash \
    git wget curl nodejs \
    sudo dumb-init \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

# Tailscale
RUN curl https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
    && curl https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && sudo apt-get update && sudo apt-get -y install tailscale \
    && mkdir -p /run/tailscale/ /var/lib/tailscale/ && chmod 1777 /run/tailscale/ /var/lib/tailscale/
    # && sudo tailscale up --authkey ${TAILSCALE_KEY}

# cockroachdb
RUN curl --create-dirs -o $HOME/.postgresql/root.crt \
    'https://cockroachlabs.cloud/clusters/37f989f0-20e5-4ff7-834b-9f3146527512/cert'

# RUN mkdir ${APP_ROOT}
ENV APP_ROOT='/app'
WORKDIR ${APP_ROOT}

# COPY Gemfile ${APP_ROOT}/Gemfile
# COPY Gemfile.lock ${APP_ROOT}/Gemfile.lock

COPY . ${APP_ROOT}

EXPOSE 3000

COPY .deploy/production/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# CMD [ "dumb-init", "/bin/sh" ]
# CMD [ "rails","server", "-b", "0.0.0.0"]
CMD [ "foreman","start", "-f", "Procfile"]