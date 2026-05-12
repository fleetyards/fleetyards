# frozen_string_literal: true

require "rails_helper"

RSpec.describe "api/v1/me/calendar/events.ics", type: :request do
  let(:user) { create(:user) }
  let(:fleet) { create(:fleet, members: [user]) }
  let(:other_user) { create(:user) }
  let(:other_fleet) { create(:fleet, members: [other_user]) }

  before do
    Flipper.enable("mission_builder")
    user.ensure_calendar_feed_token!
  end

  def signup_for(membership, event, status: "confirmed")
    create(:fleet_event_signup,
      fleet_event: event, fleet_membership: membership,
      fleet_event_slot: nil, status: status)
  end

  it "returns only events the user has signed up for" do
    membership = fleet.fleet_memberships.find_by(user: user)
    mine = create(:fleet_event, :open, fleet: fleet, title: "My Op",
      starts_at: 2.days.from_now)
    not_mine = create(:fleet_event, :open, fleet: fleet, title: "Other Op",
      starts_at: 2.days.from_now)
    signup_for(membership, mine)

    get "/api/v1/me/calendar/events.ics", params: {token: user.calendar_feed_token}

    expect(response).to have_http_status(:ok)
    expect(response.media_type).to eq("text/calendar")
    expect(response.body).to include("My Op")
    expect(response.body).not_to include("Other Op")
    expect(not_mine).to be_present
  end

  it "scopes to the user's own signups (not other users')" do
    other_membership = other_fleet.fleet_memberships.find_by(user: other_user)
    theirs = create(:fleet_event, :open, fleet: other_fleet,
      title: "Their Op", starts_at: 2.days.from_now)
    signup_for(other_membership, theirs)

    get "/api/v1/me/calendar/events.ics", params: {token: user.calendar_feed_token}

    expect(response).to have_http_status(:ok)
    expect(response.body).not_to include("Their Op")
  end

  it "returns 403 with no token" do
    get "/api/v1/me/calendar/events.ics"

    expect(response).to have_http_status(:forbidden)
  end

  it "returns 403 with a wrong token" do
    get "/api/v1/me/calendar/events.ics", params: {token: "nope"}

    expect(response).to have_http_status(:forbidden)
  end
end
