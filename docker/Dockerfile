FROM ruby:2.5.1

RUN curl https://deb.nodesource.com/setup_9.x | bash - \
    && apt-get install -y --no-install-recommends \
    nodejs

RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
    && echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list

RUN apt-get install -y --no-install-recommends \
    vim git yarn rsync patch postgresql postgresql-contrib python-psycopg2 build-essential cmake \
    imagemagick openssl libreadline6-dev zlib1g zlib1g-dev libssl-dev libyaml-dev libpq-dev \
    libxml2-dev libxslt-dev libc6-dev libicu-dev libqtwebkit-dev qt4-qmake xvfb bzip2 libssl-dev \
    unzip \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

RUN gem install bundler

CMD [ "bash" ]
