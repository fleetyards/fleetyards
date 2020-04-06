FROM ruby:2.6.6

RUN curl https://deb.nodesource.com/setup_10.x | bash - \
    && curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

## install main deps
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs yarn rsync patch postgresql-client python-psycopg2 \
    build-essential cmake imagemagick openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev \
    libyaml-dev libpq-dev libxml2-dev libxslt-dev libc6-dev libicu-dev libqtwebkit-dev qt4-qmake \
    xvfb bzip2 libssl-dev unzip \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN npm install -g npm@6.9.0

## install bundler
RUN gem update --system
RUN gem install bundler -v 2.0.2

RUN mkdir /app
WORKDIR /app
