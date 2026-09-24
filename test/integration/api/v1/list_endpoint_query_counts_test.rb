# frozen_string_literal: true

require "test_helper"

# These endpoints render a partial reaching for a dozen associations, and the
# ship partial alone renders twenty attachments -- each two queries per row
# unpreloaded. That made the hangar issue 47,937 queries for 5,992 vehicles.
#
# What is asserted is that the count does not grow with the number of rows,
# rather than a fixed budget: the number moves whenever a partial gains a field,
# and a budget would either be re-baselined on every change or fail for the
# wrong reason. Growth with row count is the actual defect.
class Api::V1::ListEndpointQueryCountsTest < ActionDispatch::IntegrationTest
  def count_queries
    count = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      count += 1 unless payload[:name].to_s.match?(/SCHEMA|TRANSACTION/)
    end
    yield
    count
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end

  test "the hangar issues the same number of queries for one vehicle as for many" do
    user = create(:user)
    sign_in user

    create(:vehicle, user:)
    get "/api/v1/hangar"
    assert_response :success
    for_one = count_queries { get "/api/v1/hangar" }

    create_list(:vehicle, 8, user:)
    for_many = count_queries { get "/api/v1/hangar" }

    assert_response :success
    assert_equal 9, response.parsed_body["items"].size
    assert_equal for_one, for_many,
      "hangar queries grew from #{for_one} to #{for_many} between 1 and 9 vehicles"
  end

  # The blueprint row renders through `facts`, which is the build we are on or
  # the last one that described the recipe -- so the fallback build has to be
  # preloaded as well as the current one. Asked with `currentVersion=false`,
  # which is the request that returns rows rendered off it.
  test "the blueprints index issues the same number of queries for one recipe as for many" do
    # Holds the configured build, so the rows below are genuinely retired
    # rather than the newest thing there is.
    create(:blueprint)

    retired_recipe = lambda do
      blueprint = create(:blueprint, :without_build, version: nil)
      last = blueprint.builds.create!(environment: ScData::Source.environment, version: "0.0.1-live.1")
      create(:blueprint_source, build: last, alignment: "outlaw")
      create(:blueprint_cost_slot, build: last)
    end

    retired_recipe.call
    fallback = {q: {currentVersion: false}}

    get "/api/v1/blueprints", params: fallback
    assert_response :success
    for_one = count_queries { get "/api/v1/blueprints", params: fallback }

    8.times { retired_recipe.call }
    for_many = count_queries { get "/api/v1/blueprints", params: fallback }

    assert_response :success
    assert_equal 10, response.parsed_body["items"].size
    assert_equal for_one, for_many,
      "blueprint queries grew from #{for_one} to #{for_many} between 2 and 10 recipes"
  end

  # Each squadron's size is counted outside the cached fragment, so the roster
  # has to be preloaded or the list issues one count per squadron.
  test "the squadrons index issues the same number of queries for one squadron as for many" do
    Flipper.enable("fleet_squadrons")
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    sign_in admin

    squadron_with_members = lambda do
      squadron = create(:fleet_squadron, fleet:)
      2.times do
        create(:fleet_squadron_membership,
          fleet_squadron: squadron,
          fleet_membership: create(:fleet_membership, :accepted, fleet:))
      end
    end

    squadron_with_members.call
    path = "/api/v1/fleets/#{fleet.slug}/squadrons"

    get path
    assert_response :success
    for_one = count_queries { get path }

    8.times { squadron_with_members.call }
    for_many = count_queries { get path }

    assert_response :success
    assert_equal 9, response.parsed_body["items"].size
    assert_equal for_one, for_many,
      "squadron queries grew from #{for_one} to #{for_many} between 1 and 9 squadrons"
  end

  test "the models index issues the same number of queries for one ship as for many" do
    create(:model)
    get "/api/v1/models"
    assert_response :success
    for_one = count_queries { get "/api/v1/models" }

    create_list(:model, 8)
    for_many = count_queries { get "/api/v1/models" }

    assert_response :success
    assert_equal for_one, for_many,
      "models queries grew from #{for_one} to #{for_many} between 1 and 9 ships"
  end
end
