FROM ruby:3.1.2

ENV APP_ROOT='/app' TAILSCALE_KEY=''

RUN apt-get update && apt-get install -y \
    build-essential libpq-dev \
    # sqlite-dev postgresql-dev postgresql-client mysql-client \
    vim nano bash \
    git wget curl nodejs \
    sudo dumb-init \
    # shadow \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

# Tailscale
RUN curl https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
    && curl https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && sudo apt-get update && sudo apt-get -y install tailscale 
    && sudo tailscale up --authkey ${TAILSCALE_KEY}

# cockroachdb
RUN curl --create-dirs -o $HOME/.postgresql/root.crt \
    'https://cockroachlabs.cloud/clusters/37f989f0-20e5-4ff7-834b-9f3146527512/cert'

RUN mkdir ${APP_ROOT}
WORKDIR ${APP_ROOT}

COPY Gemfile ${APP_ROOT}/Gemfile
COPY Gemfile.lock ${APP_ROOT}/Gemfile.lock

COPY . ${APP_ROOT}

# EXPOSE 3000

COPY .deploy/production/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

CMD [ "dumb-init", "/bin/sh" ]
# CMD [ "rails","server","--bind","0.0.0.0","--environment","production" ]
# CMD [ "rails","server","--bind","0.0.0.0","--environment","production" ]