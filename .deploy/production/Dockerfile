FROM ruby:3.1.2

ENV APP_ROOT='/app' TAILSCALE_KEY=''

RUN apt-get update && apt-get install -y \
    build-essential libpq-dev \
    sqlite-dev postgresql-dev postgresql-client mysql-client \
    git wget vim nano sudo bash curl shadow dumb-init nodejs \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

RUN curl https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
    && curl https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && sudo apt-get update && sudo apt-get install tailscale \
    && sudo tailscale up --authkey ${TAILSCALE_KEY}

RUN mkdir ${APP_ROOT}
WORKDIR ${APP_ROOT}

COPY Gemfile ${APP_ROOT}/Gemfile
COPY Gemfile.lock ${APP_ROOT}/Gemfile.lock

COPY . ${APP_ROOT}

COPY docker/deploy/staging/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

EXPOSE 3000

# CMD [ "dumb-init", "/bin/sh" ]
CMD [ "rails","server","--bind","0.0.0.0","--environment","production" ]