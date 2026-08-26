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
