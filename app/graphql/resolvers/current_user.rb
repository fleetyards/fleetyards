# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class CurrentUser < Resolvers::Base
    def resolve
      current_user
    end
  end
end
