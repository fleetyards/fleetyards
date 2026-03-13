# syntax=docker/dockerfile:1

# Stage 1: Base image with system dependencies
ARG RUBY_VERSION=3.4.5
FROM ruby:${RUBY_VERSION}-slim AS base

WORKDIR /rails

# Install base runtime packages (no build tools)
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      imagemagick \
      libcurl4 \
      libpq5 \
      libvips42 \
      poppler-utils \
      ffmpeg \
      shared-mime-info \
      postgresql-client \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Stage 2: Build gems and frontend assets
FROM base AS build

# Install build dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      git \
      gnupg2 \
      libcurl4-openssl-dev \
      libmagickwand-dev \
      libpq-dev \
      libyaml-dev \
      node-gyp \
      pkg-config \
      python-is-python3 \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install Node.js and pnpm
ARG NODE_MAJOR=24
RUN curl -fsSL https://deb.nodesource.com/setup_${NODE_MAJOR}.x | bash - && \
    apt-get install --no-install-recommends -y nodejs && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives
RUN corepack enable && corepack prepare pnpm@10.31.0 --activate

# Install Ruby gems
COPY Gemfile Gemfile.lock .tool-versions ./
RUN bundle install --jobs 4 && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Install Node dependencies (skip postinstall, orval runs after full copy)
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --ignore-scripts

# Copy the rest of the application
COPY . .

# Run postinstall scripts now that full source is available
RUN pnpm run postinstall

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Build frontend assets with Vite
RUN SECRET_KEY_BASE_DUMMY=1 bin/rails assets:precompile

# Stage 3: Final production image
FROM base

# Copy built gems
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"

# Copy application code
COPY --from=build /rails /rails

# Clean up files not needed in production
RUN rm -rf \
      app/frontend \
      node_modules \
      spec \
      test \
      tmp/cache \
      vendor/assets \
    && mkdir -p tmp/pids tmp/cache log

# Run as non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000

CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
