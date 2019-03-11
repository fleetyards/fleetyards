FROM fleetyards/base:2.5.1

## install chrome
RUN curl -L https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - \
    && echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list

RUN apt-get update && apt-get install -y --no-install-recommends \
    google-chrome-stable git libgtk2.0-0 libnotify-dev libgconf-2-4 libnss3 libxss1 libasound2 \
    && ln -s /opt/google/chrome/chrome /usr/bin/chrome \
    && apt-get clean \
    && rm -rf /tmp/* /var/lib/apt/lists/*
