# frozen_string_literal: true

class Faction < ApplicationRecord
  before_save :update_slugs
end
