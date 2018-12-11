# frozen_string_literal: true

class Affiliation < ApplicationRecord
  belongs_to :affiliationable, polymorphic: true
  belongs_to :faction
end
