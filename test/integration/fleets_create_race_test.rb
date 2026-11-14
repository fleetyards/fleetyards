# frozen_string_literal: true

require "test_helper"

# Lives outside test/integration/api/v1 on purpose: it asserts behaviour under a
# concurrent insert rather than a documented response, so it must not contribute
# to the generated OpenAPI schema.
class FleetsCreateRaceTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    create(:fleet, fid: "STARFLEET")
    sign_in @user
  end

  test "creating a fleet whose FID another request just took answers 400 rather than 500" do
    # The uniqueness validation is a read, so a request whose validation ran
    # before the winner's row landed reaches the insert regardless.
    Fleet.any_instance.stubs(:valid?).returns(true)

    assert_no_difference -> { Fleet.count } do
      post "/api/v1/fleets", params: {fid: "STARFLEET", name: "Starfleet"}, as: :json
    end

    assert_equal 400, response.status
    body = JSON.parse(response.body)
    assert_equal "validation_error.fleet.create", body["code"]
  end
end
