# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class Hangar < Resolvers::Base
    def resolve
      search = user.user_ships
                   .ransack(args[:q].to_h)

      search.sorts = ['purchased desc', 'name asc', 'created_at desc'] if search.sorts.empty?

      search.result
            .offset(args[:offset])
            .limit(args[:limit])
    end

    private def user
      @user ||= current_user
      @user ||= User.find_by(username: args[:username])
    end
  end
end
