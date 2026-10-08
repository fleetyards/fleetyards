# frozen_string_literal: true

module Imports
  class UexEquipmentPricesImport < ::Import
    belongs_to :admin_user, optional: true
  end
end
