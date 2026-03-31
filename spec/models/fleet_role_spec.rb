# frozen_string_literal: true

# == Schema Information
#
# Table name: fleet_roles
#
#  id              :uuid             not null, primary key
#  name            :string
#  permanent       :boolean
#  rank            :text
#  resource_access :text
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  fleet_id        :uuid             not null
#
# Indexes
#
#  index_fleet_roles_on_fleet_id_and_rank  (fleet_id,rank) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (fleet_id => fleets.id)
#
require "rails_helper"

RSpec.describe FleetRole, type: :model do
  it { is_expected.to belong_to(:fleet) }
end
