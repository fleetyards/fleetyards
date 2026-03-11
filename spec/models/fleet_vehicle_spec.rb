# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetVehicle, type: :model do
  it { is_expected.to belong_to(:vehicle) }
  it { is_expected.to belong_to(:fleet) }
end
