# frozen_string_literal: true

# rubocop:disable Style/AccessModifierDeclarations

require 'devise/controllers/rememberable'

::Devise::Controllers::Rememberable.class_eval do
  protected

  def remember_key(resource, scope)
    fallback_key = if Rails.env.production?
                     "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED"
                   else
                     "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED_#{Rails.env.upcase}"
                   end

    resource.rememberable_options.fetch(:key, fallback_key)
  end
end

require 'devise/strategies/base'
require 'devise/strategies/rememberable'

::Devise::Strategies::Rememberable.class_eval do
  private

  def remember_key
    fallback_key = if Rails.env.production?
                     "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED"
                   else
                     "#{Rails.configuration.cookie_prefix}_#{scope.upcase}_STORED_#{Rails.env.upcase}"
                   end

    mapping.to.rememberable_options.fetch(:key, fallback_key)
  end
end
# rubocop:enable Style/AccessModifierDeclarations
