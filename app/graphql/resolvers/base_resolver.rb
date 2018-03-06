# frozen_string_literal: true

module Resolvers
  class BaseResolver
    attr_accessor :obj, :args, :ctx, :errors

    def call(obj, args, ctx)
      self.obj = obj
      self.args = args
      self.ctx = ctx
      self.errors = []

      check_authentication

      result = resolve

      if errors.present?
        handle_errors
        nil
      else
        result
      end
    end

    def resolve
      raise NotImplementedError
    end

    def current_user
      ctx[:current_user]
    end

    def current_ability
      ::Ability.new(current_user)
    end

    private def check_authentication
      return unless needs_authentication? && current_user.blank?
      errors << { code: 'authentication_needed', message: 'Field needs Authentication' }
    end

    private def needs_authentication?
      metadata[:needs_authentication] || false
    end

    private def metadata
      ctx.field.metadata
    end

    private def add_not_found_error
      errors << { code: 'not_found', message: I18n.t('error_messages.record_not_found') }
    end

    private def add_active_record_errors(result)
      return if !defined?(result.errors) || result.errors.blank?
      active_record_errors = result.errors
      active_record_errors.details.each do |(error)|
        errors << { code: error, message: active_record_errors.full_messages_for(error).join(', ') }
      end
    end

    private def handle_errors
      errors.each do |error|
        handle_error(error[:message], error[:code])
      end
    end

    private def handle_error(message, path)
      error = GraphQL::ExecutionError.new(message)
      error.path = "#{class_name}.#{path}"
      ctx.add_error(error)
    end

    private def class_name
      self.class.name.demodulize.underscore.chomp('_resolver')
    end
  end
end
