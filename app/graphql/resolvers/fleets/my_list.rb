# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class MyList < Resolvers::Base
      def resolve
        current_user.fleets.order(name: :asc)
      end
    end
  end
end
