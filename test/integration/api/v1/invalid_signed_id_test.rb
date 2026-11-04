# frozen_string_literal: true

require "test_helper"

class Api::V1::InvalidSignedIdTest < ActionDispatch::IntegrationTest
  test "a signed blob id that does not verify is a bad request" do
    admin = create(:user)
    fleet = create(:fleet, admins: [admin])
    sign_in admin

    put "/api/v1/fleets/#{fleet.slug}", params: {logo: "forged--0000"}, as: :json

    assert_response :bad_request
    assert_equal "invalid_signed_id", response.parsed_body["code"]
    assert_not fleet.reload.logo.attached?
  end

  test "the admin API answers the same way" do
    admin = create(:admin_user, resource_access: [:fleets])
    fleet = create(:fleet)
    sign_in admin

    put "/admin/api/v1/fleets/#{fleet.id}", params: {logo: "forged--0000"}, as: :json

    assert_response :bad_request
    assert_equal "invalid_signed_id", response.parsed_body["code"]
  end
end
