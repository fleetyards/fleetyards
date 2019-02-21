FROM fleetyards/base:2.5.1

## install chrome
RUN curl -L https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable vim git \
    && ln -s /opt/google/chrome/chrome /usr/bin/chrome \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*

# ## install docker
# RUN curl -L -o /tmp/docker-17.03.0-ce.tgz https://download.docker.com/linux/static/stable/x86_64/docker-17.03.0-ce.tgz \
#     && tar -xz -C /tmp -f /tmp/docker-17.03.0-ce.tgz \
#     && mv /tmp/docker/* /usr/bin

# ## install docker compose
# RUN curl -L https://github.com/docker/compose/releases/download/1.23.2/docker-compose-`uname -s`-`uname -m` > ~/docker-compose \
#     && chmod +x ~/docker-compose \
#     && mv ~/docker-compose /usr/local/bin/docker-compose
