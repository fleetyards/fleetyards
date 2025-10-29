ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION-slim as base

ARG NODE_MAJOR
ARG BUNDLER_VERSION
ARG PNPM_VERSION

WORKDIR /app

COPY Gemfile Gemfile.lock .ruby-version ./

# Upgrade RubyGems and install required Bundler version
RUN gem update --system --no-document && \
    gem install -N bundler:$BUNDLER_VERSION

# add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# install packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    nodejs=$NODE_VERSION* npm poppler-utils ffmpeg libmagickwand-dev build-essential libpq-dev \
    shared-mime-info libcurl4-openssl-dev git gnupg2 imagemagick postgresql-common \
    postgresql-client \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN npm install -g pnpm

RUN bundle install --jobs 4

COPY package.json pnpm-lock.yaml ./
RUN pnpm install

COPY . /app

# Add a script to be executed every time the container starts.
COPY docker/entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]

RUN mkdir -p /app/tmp/pids && mkdir -p /app/log

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]


