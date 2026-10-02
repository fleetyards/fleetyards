# frozen_string_literal: true

require "test_helper"

# == Schema Information
#
# Table name: terminals
#
#  id                   :uuid             not null, primary key
#  available            :boolean          default(TRUE), not null
#  city                 :string
#  code                 :string
#  contact_url          :string
#  display_name         :string
#  has_docking_port     :boolean          default(FALSE), not null
#  has_freight_elevator :boolean          default(FALSE), not null
#  has_loading_dock     :boolean          default(FALSE), not null
#  max_container_size   :integer
#  moon                 :string
#  name                 :string           not null
#  nickname             :string
#  orbit                :string
#  outpost              :string
#  planet               :string
#  player_owned         :boolean          default(FALSE), not null
#  source_updated_at    :datetime
#  space_station        :string
#  star_system          :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  location_id          :uuid
#  uex_id               :integer          not null
#
# Indexes
#
#  index_terminals_on_location_id  (location_id)
#  index_terminals_on_star_system  (star_system)
#  index_terminals_on_uex_id       (uex_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (location_id => locations.id) ON DELETE => nullify
#
class TerminalTest < ActiveSupport::TestCase
  test "a station is not on a surface, even over a planet" do
    station = create(:terminal, space_station: "ARC-L1 Wide Forest Station", city: nil, outpost: nil)

    assert_not station.on_surface?
    assert_not_includes Terminal.on_surface, station
  end

  test "a city or an outpost is on a surface" do
    city = create(:terminal, city: "Area 18")
    outpost = create(:terminal, outpost: "Shubin SM0-10")

    assert city.on_surface?
    assert outpost.on_surface?
    assert_equal [city, outpost].sort_by(&:id), Terminal.on_surface.sort_by(&:id)
  end

  test "a terminal with no place recorded is not called a surface" do
    unknown = create(:terminal)

    assert_not unknown.on_surface?
    assert_not_includes Terminal.on_surface, unknown
  end
end
