# encoding: utf-8
# frozen_string_literal: true

require 'rsi_orgs_loader'

module Resolvers
  class Org < Resolvers::Base
    def resolve
      RsiOrgsLoader.new.fetch(sid)
    end

    private def sid
      args[:sid].downcase
    end
  end
end
