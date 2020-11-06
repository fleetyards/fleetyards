# frozen_string_literal: true

# == Schema Information
#
# Table name: affiliations
#
#  id                   :uuid             not null, primary key
#  affiliationable_type :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  affiliationable_id   :uuid
#  faction_id           :uuid
#
# Indexes
#
#  index_affiliations_on_affiliationable  (affiliationable_type,affiliationable_id)
#  index_affiliations_on_faction_id       (faction_id)
#
class Affiliation < ApplicationRecord
  belongs_to :affiliationable, polymorphic: true
  belongs_to :faction
end
