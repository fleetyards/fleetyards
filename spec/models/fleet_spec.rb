# frozen_string_literal: true

require "rails_helper"

RSpec.describe Fleet, type: :model do
  describe "#setup_default_roles!" do
    it "creates 3 default roles on fleet creation" do
      fleet = create(:fleet)

      expect(fleet.fleet_roles.count).to eq(3)
    end
  end

  describe "#default_member_role" do
    it "returns the last ranked role" do
      fleet = create(:fleet)

      expect(fleet.default_member_role.name).to eq("Member")
    end

    it "creates roles if none exist" do
      fleet = create(:fleet)
      fleet.fleet_roles.destroy_all

      expect(fleet.fleet_roles.reload.count).to eq(0)

      role = fleet.default_member_role

      expect(role.name).to eq("Member")
      expect(fleet.fleet_roles.reload.count).to eq(3)
    end
  end

  describe "url validation" do
    let(:user) { create(:user) }
    let(:fleet) { create(:fleet, created_by: user.id) }

    %w[guilded homepage discord twitch youtube].each do |field|
      it "strips protocol from #{field} url" do
        fleet.update!(field => "https://foo.bar")
        fleet.reload

        expect(fleet.send(field)).to eq("foo.bar")
      end

      it "strips double slashes from #{field} url" do
        fleet.update!(field => "//foo.bar")
        fleet.reload

        expect(fleet.send(field)).to eq("foo.bar")
      end
    end

    it "adds ts3server protocol to ts url" do
      fleet.update!(ts: "foo.bar")
      fleet.reload

      expect(fleet.ts).to eq("ts3server://foo.bar")
    end

    it "replaces http with ts3server for ts url" do
      fleet.update!(ts: "http://foo.bar")
      fleet.reload

      expect(fleet.ts).to eq("ts3server://foo.bar")
    end

    it "replaces https with ts3server for ts url" do
      fleet.update!(ts: "https://foo.bar")
      fleet.reload

      expect(fleet.ts).to eq("ts3server://foo.bar")
    end
  end
end
