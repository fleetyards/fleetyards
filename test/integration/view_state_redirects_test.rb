# frozen_string_literal: true

require "test_helper"

# Views that were paths of their own and are query state now. Every one of the
# old paths is live -- mail already sent carries the invite list's, and the
# others have been shared and bookmarked -- so they resolve from the server
# rather than by loading the app and bouncing off the client router.
class ViewStateRedirectsTest < ActionDispatch::IntegrationTest
  REDIRECTS = {
    "/hangar/transactions" => "/hangar/inventories/?tab=log",
    "/hangar/transfers/outgoing" => "/hangar/transfers/?direction=outgoing",
    "/hangar/inventories/crates/transactions" => "/hangar/inventories/crates/?tab=log",
    "/hangar/my-vehicle/cargo/transactions" => "/hangar/my-vehicle/cargo/?tab=log",
    "/fleets/black-sun/members/invites" => "/fleets/black-sun/members/?view=invites",
    "/fleets/black-sun/logistics/transactions" => "/fleets/black-sun/logistics/?tab=log",
    "/fleets/black-sun/logistics/transfers/outgoing" =>
      "/fleets/black-sun/logistics/transfers/?direction=outgoing",
    "/fleets/black-sun/logistics/inventories/crates/transactions" =>
      "/fleets/black-sun/logistics/inventories/crates/?tab=log"
  }.freeze

  REDIRECTS.each do |from, to|
    # The status is the assertion that matters: `hangar/:username` renders the
    # app shell for a username nobody has, so a hangar path declared below it
    # answers 200 and quietly never redirects.
    test "GET #{from} lands on the view it became" do
      get from

      assert_response :moved_permanently
      assert_equal "http://www.example.com#{to}", response.location
    end
  end

  # Repeated keys reach the client router as an array, and what reads them there
  # expects one value -- so the view the path names has to replace the one the
  # link carried rather than queue behind it.
  test "the view the path names wins over one the link carried" do
    get "/hangar/transactions?tab=stock&page=2"

    assert_response :moved_permanently
    assert_equal "http://www.example.com/hangar/inventories/?tab=log&page=2", response.location
  end

  # vue-router writes a filter holding more than one value as a repeated key, so
  # the carried query is split rather than parsed and rebuilt.
  test "it keeps a filter that repeats its key" do
    get "/fleets/black-sun/members/invites?roleIn=admin&roleIn=officer"

    assert_response :moved_permanently
    assert_equal "http://www.example.com/fleets/black-sun/members/?view=invites&roleIn=admin&roleIn=officer",
      response.location
  end

  test "it keeps what the link carried" do
    get "/fleets/black-sun/members/invites?page=2"

    assert_response :moved_permanently
    assert_equal "http://www.example.com/fleets/black-sun/members/?view=invites&page=2",
      response.location
  end

  # The block is declared above `hangar/:username` so the literal path wins, and
  # one of its entries sits a segment below the members page. Neither of the
  # routes it was put in front of may stop answering its own path.
  test "the routes the redirects were declared around still answer their own" do
    assert_equal "frontend/hangar#public", recognized("/hangar/mortik")
    assert_equal "frontend/fleets#members", recognized("/fleets/black-sun/members/")
  end

  private def recognized(path)
    route = Rails.application.routes.recognize_path(path, method: :get)

    "#{route[:controller]}##{route[:action]}"
  end
end
