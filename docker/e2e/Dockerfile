FROM fleetyards/base:2.5.1

## install chrome
RUN curl -L https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable vim git \
    && ln -s /opt/google/chrome/chrome /usr/bin/chrome \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

ARG APP_DIR
ARG RAILS_ENV

ENV APP_DIR ${APP_DIR:-.}
ENV RAILS_ENV ${RAILS_ENV:-docker}

## copy source
COPY . /app

RUN mkdir -p /app/tmp/pids

## install gems
RUN bundle install --path vendor/bundle

## install packages
RUN yarn install --check-files

## setup entrypoint
COPY entrypoint.sh /usr/bin/
RUN chmod +x /usr/bin/entrypoint.sh
ENTRYPOINT ["entrypoint.sh"]
EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
