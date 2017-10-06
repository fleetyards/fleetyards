# encoding: utf-8
# frozen_string_literal: true

require 'rsi_orgs_loader'

module Resolvers
  class Orgs < Resolvers::Base
    def resolve
      return detail if sid.present?

      collection
    end

    private def collection
      q = RsiOrg.ransack(args[:q].to_h)

      q.sorts = 'name asc' if q.sorts.empty?

      q.result
       .offset(args[:offset])
       .limit(args[:limit])
    end

    private def detail
      RsiOrg.find_by(sid: sid) || RsiOrgsLoader.new.fetch(sid)
    end

    private def sid
      @sid ||= args[:sid].present? && args[:sid].downcase
    end
  end
end
