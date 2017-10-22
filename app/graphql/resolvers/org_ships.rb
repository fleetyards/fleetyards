# encoding: utf-8
# frozen_string_literal: true

module Resolvers
  class OrgShips < Resolvers::Base
    def resolve
      search = UserShip.includes(:user, :ship)
                       .where("users.rsi_org = ?", sid)
                       .references(:user)
                       .purchased
                       .ransack(args[:q].to_h)

      search.sorts = 'ships.name asc' if search.sorts.empty?

      search.result
            .offset(args[:offset])
            .limit(args[:limit])
    end

    private def sid
      @sid = args[:sid].downcase
    end
  end
end
