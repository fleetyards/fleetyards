ARG RUBY_VERSION=3.0.2

FROM ruby:$RUBY_VERSION-slim

ARG NODE_VERSION=14
ARG BUNDLER_VERSION=2.2.23

ENV RAILS_ENV=production

## install main deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN curl https://deb.nodesource.com/setup_current.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN curl -sS https://deb.nodesource.com/gpgkey/nodesource.gpg.key | apt-key add -\
    && echo "deb https://deb.nodesource.com/node_${NODE_VERSION}.x focal main" | tee /etc/apt/sources.list.d/node.list

## install main deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs=$NODE_VERSION* yarn git gcc g++ make rsync patch postgresql-client build-essential \
    cmake imagemagick openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev \
    libpq-dev libxml2-dev libxslt-dev libc6-dev libicu-dev xvfb bzip2 libssl-dev \
    unzip shared-mime-info \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

## install bundler
RUN gem update --system && gem install bundler -v $BUNDLER_VERSION

WORKDIR /fleetyards

COPY app /fleetyards/app
COPY config /fleetyards/config
COPY db /fleetyards/db
COPY bin /fleetyards/bin
COPY lib /fleetyards/lib
COPY public /fleetyards/public
COPY vendor /fleetyards/vendor
COPY .ruby-version /fleetyards/.ruby-version
COPY Rakefile /fleetyards/Rakefile
COPY Gemfile /fleetyards/Gemfile
COPY Gemfile.lock /fleetyards/Gemfile.lock
COPY config.ru /fleetyards/config.ru

RUN bundle install

# Add a script to be executed every time the container starts.
COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN mkdir -p /fleetyards/tmp/pids && mkdir -p /fleetyards/log

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]


