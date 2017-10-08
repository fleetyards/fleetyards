# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Users
    class Signup < Resolvers::Base
      def resolve
        user = User.new(args[:data].to_h)

        add_active_record_errors(user) unless user.save

        user
      end
    end
  end
end
