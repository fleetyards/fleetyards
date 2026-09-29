# frozen_string_literal: true

require "test_helper"

class Short::PublicHangarTest < ActionDispatch::IntegrationTest
  setup do
    host! Rails.configuration.app.short_domain
  end

  test "redirects a hangar to the public hangar" do
    get "/h/data"

    assert_response :found
    assert_match(%r{/hangar/data/\z}, response.location)
  end

  test "redirects a hangar's stats to its stats page" do
    get "/h/data/stats"

    assert_response :found
    assert_match(%r{/hangar/data/stats/\z}, response.location)
  end

  test "redirects a hangar's fleetchart to its fleetchart page" do
    get "/h/data/fleetchart"

    assert_response :found
    assert_match(%r{/hangar/data/fleetchart/\z}, response.location)
  end
end
