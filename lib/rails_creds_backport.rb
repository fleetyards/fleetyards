# frozen_string_literal: true

# Backport of Rails 8.2 `Rails.app.creds` unified credential access.
#
# This provides a single API to look up secrets from ENV, .env files (dev only),
# and encrypted credentials, in that priority order.
#
# REMOVAL: Delete this file, lib/rails_creds_backport/, and
#          config/initializers/rails_creds_backport.rb once you upgrade to Rails 8.2.
#
# See: https://github.com/rails/rails/pull/56404
#      https://github.com/rails/rails/pull/56455

require_relative "rails_creds_backport/env_configuration"
require_relative "rails_creds_backport/dot_env_configuration"
require_relative "rails_creds_backport/combined_configuration"
require_relative "rails_creds_backport/encrypted_configuration_ext"
require_relative "rails_creds_backport/application_ext"
