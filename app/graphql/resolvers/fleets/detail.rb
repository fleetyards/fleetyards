# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  module Fleets
    class Detail < Resolvers::Base
      def resolve
        ::Fleet.find_by!(sid: args[:sid])
      end
    end
  end
end
