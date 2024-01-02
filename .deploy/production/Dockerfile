FROM ruby:3.1.2

ENV APP_ROOT='/app'

RUN apt-get update && apt-get install -y \
    build-essential libmsgpack-dev \
    # libpq-dev postgresql-server-dev-all \
    # sqlite-dev postgresql-dev postgresql-client mysql-client \
    vim nano bash \
    git wget curl nodejs \
    sudo dumb-init \
    # shadow \
   && apt-get clean \
   && rm -rf /var/lib/apt/lists/*

# postgresql (postgresql-client-12 postgresql-12 libpq-dev postgresql-server-dev-12 :https://www.postgresql.org/download/linux/ubuntu/)
RUN echo "deb https://apt.postgresql.org/pub/repos/apt $(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)-pgdg main" > /etc/apt/sources.list.d/pgdg.list \
    && wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor - | sudo tee /usr/share/keyrings/postgresql-archive-keyring.gpg \
    && echo "signed-by=/usr/share/keyrings/postgresql-archive-keyring.gpg" >> /etc/apt/sources.list.d/pgdg.list \
    && apt-get update && apt-get -y install postgresql

# Tailscale
RUN curl https://pkgs.tailscale.com/stable/ubuntu/focal.gpg | sudo apt-key add - \
    && curl https://pkgs.tailscale.com/stable/ubuntu/focal.list | sudo tee /etc/apt/sources.list.d/tailscale.list \
    && sudo apt-get update && sudo apt-get -y install tailscale 
    # && sudo tailscale up --authkey ${TAILSCALE_KEY}

# cockroachdb
RUN curl --create-dirs -o $HOME/.postgresql/root.crt \
    'https://cockroachlabs.cloud/clusters/37f989f0-20e5-4ff7-834b-9f3146527512/cert'

# RUN mkdir ${APP_ROOT}
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