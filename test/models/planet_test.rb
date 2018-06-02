# frozen_string_literal: true

require 'test_helper'

class PlanetTest < ActiveSupport::TestCase
  should belong_to(:starsystem)
  should belong_to(:planet)

  should validate_presence_of(:name)
  should validate_presence_of(:name)

  let(:stanton) { starsystems :stanton }
  let(:hurston) { planets :hurston }
  let(:uriel) { planets :uriel }

  test "custom validations" do
    planet = Planet.new(name: 'Earth')
    assert_equal planet.valid?, false
  end

  test "custom validations with system" do
    planet = Planet.new(name: 'Earth', starsystem: stanton)
    assert_equal planet.valid?, true
  end

  test "custom validations with planet" do
    planet = Planet.new(name: 'Earth', planet: hurston)
    assert_equal planet.valid?, true
  end

  test "before save callback for system" do
    planet = Planet.create(name: 'Earth', planet: hurston)
    assert_equal planet.starsystem_id, hurston.starsystem_id
  end

  test "before save callback for system on update" do
    planet = Planet.create(name: 'Earth', planet: hurston)

    planet.update(planet: uriel)

    assert_not_equal planet.starsystem_id, hurston.starsystem_id
    assert_equal planet.starsystem_id, uriel.starsystem_id
  end
end
