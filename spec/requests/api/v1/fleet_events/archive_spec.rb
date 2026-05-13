# frozen_string_literal: true

require "rails_helper"

RSpec.describe "FleetEvent archive flow", type: :request do
  let(:admin) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin]) }
  let(:event) { create(:fleet_event, :open, fleet: fleet, created_by: admin) }

  before do
    Flipper.enable("mission_builder")
    sign_in(admin)
  end

  describe "DELETE /api/v1/fleets/:slug/events/:event" do
    it "archives a non-archived event instead of destroying it" do
      delete "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}", as: :json
      expect(response).to have_http_status(:ok)
      expect(event.reload.archived?).to be true
    end

    it "destroys an already-archived event" do
      event.archive!
      delete "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}", as: :json
      expect(response).to have_http_status(:no_content)
      expect(FleetEvent.exists?(event.id)).to be false
    end
  end

  describe "PUT /api/v1/fleets/:slug/events/:event/unarchive" do
    it "restores an archived event" do
      event.archive!
      put "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/unarchive", as: :json
      expect(response).to have_http_status(:ok)
      expect(event.reload.archived?).to be false
    end

    it "returns 400 when the event is not archived" do
      put "/api/v1/fleets/#{fleet.slug}/events/#{event.slug}/unarchive", as: :json
      expect(response).to have_http_status(:bad_request)
    end
  end

  describe "GET /api/v1/fleets/:slug/events index filter" do
    it "hides archived events by default" do
      event.archive!
      create(:fleet_event, :open, fleet: fleet, created_by: admin)

      get "/api/v1/fleets/#{fleet.slug}/events", as: :json
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["items"].map { |e| e["id"] }
      expect(ids).not_to include(event.id)
    end

    it "returns archived events with archived=true" do
      event.archive!

      get "/api/v1/fleets/#{fleet.slug}/events", params: {archived: "true"}, as: :json
      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body)["items"].map { |e| e["id"] }
      expect(ids).to include(event.id)
    end
  end
end
