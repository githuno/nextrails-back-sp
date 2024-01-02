ARG RUBY_VERSION=3.1.2
ARG TAILSCALE_VERSEION=1.14.0

FROM ruby:${RUBY_VERSION}-alpine

RUN apk update && apk add --no-cache \
    # build-essential libmsgpack-dev \
    # libpq-dev postgresql-server-dev-all \
    alpine-sdk build-base gcompat \
    sqlite-dev postgresql-dev postgresql-client mysql-client \
    vim nano bash \
    git wget curl nodejs \
    sudo dumb-init \
    # shadow \
   && rm -rf /var/cache/apk/*

# Tailscale
RUN wget https://pkgs.tailscale.com/stable/tailscale_${TAILSCALE_VERSEION}_amd64.tgz \
    && tar xzvf tailscale_${TAILSCALE_VERSEION}_amd64.tgz \
    && mv tailscale_${TAILSCALE_VERSEION}_amd64/tailscale* /usr/bin/
# RUN curl https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
#     && curl https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
#     && sudo apt-get update && sudo apt-get -y install tailscale 
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

# EXPOSE 3000

COPY .deploy/production/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

# CMD [ "dumb-init", "/bin/sh" ]
CMD [ "rails","server","--bind","0.0.0.0","--environment","production" ]
# CMD [ "rails","server","--bind","0.0.0.0","--environment","production" ]