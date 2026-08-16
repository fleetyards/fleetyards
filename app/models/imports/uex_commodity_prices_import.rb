# frozen_string_literal: true

module Imports
  class UexCommodityPricesImport < ::Import
    belongs_to :admin_user, optional: true
  end
end
