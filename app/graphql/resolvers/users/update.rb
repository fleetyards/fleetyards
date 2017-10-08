# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Users
    class Update < Resolvers::Base
      def resolve
        user = current_user

        add_active_record_errors(user) unless user.update(args[:data].to_h)

        user
      end
    end
  end
end
