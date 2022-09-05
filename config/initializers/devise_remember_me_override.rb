# frozen_string_literal: true

# rubocop:disable Style/AccessModifierDeclarations

require "devise/controllers/rememberable"

Devise::Controllers::Rememberable.class_eval do
  protected

  def remember_key(resource, scope)
    fallback_key = "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED"

    resource.rememberable_options.fetch(:key, fallback_key)
  end
end

require "devise/strategies/base"
require "devise/strategies/rememberable"

Devise::Strategies::Rememberable.class_eval do
  private

  def remember_key
    fallback_key = "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED"

    mapping.to.rememberable_options.fetch(:key, fallback_key)
  end
end
# rubocop:enable Style/AccessModifierDeclarations
