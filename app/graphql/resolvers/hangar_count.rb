# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class HangarCount < Resolvers::Base
    def resolve
      user.user_ships.count
    end

    private def user
      @user ||= current_user
      @user ||= User.find_by(username: args[:username])
    end
  end
end
