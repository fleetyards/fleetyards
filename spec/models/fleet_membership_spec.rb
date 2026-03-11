# frozen_string_literal: true

require "rails_helper"

RSpec.describe FleetMembership, type: :model do
  let(:admin_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:fleet) { create(:fleet, admins: [admin_user], members: [member_user]) }
  let(:admin_membership) { fleet.fleet_memberships.find_by(user: admin_user) }
  let(:member_membership) { fleet.fleet_memberships.find_by(user: member_user) }

  describe "associations" do
    it { is_expected.to belong_to(:user) }
    it { is_expected.to belong_to(:fleet) }
  end

  describe "#has_access?" do
    it "delegates to fleet_role when present" do
      expect(admin_membership.has_access?(["fleet:manage"])).to be true
    end

    it "falls back to legacy role enum when fleet_role is nil" do
      admin_membership.update_columns(fleet_role_id: nil, role: FleetMembership.roles[:admin])

      expect(admin_membership.reload.has_access?(["fleet:manage"])).to be true
    end

    it "grants member legacy privileges for member role" do
      member_membership.update_columns(fleet_role_id: nil, role: FleetMembership.roles[:member])

      expect(member_membership.reload.has_access?(["fleet:memberships:read"])).to be true
    end

    it "returns false for unprivileged access with legacy member role" do
      member_membership.update_columns(fleet_role_id: nil, role: FleetMembership.roles[:member])

      expect(member_membership.reload.has_access?(["fleet:manage"])).to be false
    end

    it "returns false when both fleet_role and role are nil" do
      admin_membership.update_columns(fleet_role_id: nil, role: nil)

      expect(admin_membership.reload.has_access?(["fleet:manage"])).to be false
    end
  end

  describe "#schedule_setup_fleet_vehicles" do
    let(:other_user) { create(:user) }

    before do
      fleet
      Sidekiq::Worker.clear_all
    end

    it "enqueues setup_fleet_vehicles job on accept_request" do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: other_user.id, aasm_state: :requested)
      Sidekiq::Worker.clear_all

      membership.accept_request!

      expect(Updater::FleetMembershipVehiclesUpdateJob.jobs.size).to eq(1)
    end

    it "enqueues setup_fleet_vehicles job on accept_invitation" do
      membership = FleetMembership.create(fleet_id: fleet.id, user_id: other_user.id, aasm_state: :invited)
      Sidekiq::Worker.clear_all

      membership.accept_invitation!

      expect(Updater::FleetMembershipVehiclesUpdateJob.jobs.size).to eq(1)
    end
  end

  describe "#schedule_update_fleet_vehicles" do
    before do
      fleet
      Sidekiq::Worker.clear_all
    end

    it "enqueues update_fleet_vehicles job" do
      admin_membership.update(ships_filter: :hide)

      expect(Updater::FleetMembershipVehiclesUpdateJob.jobs.size).to eq(1)
    end

    it "does not enqueue setup_fleet_vehicles job when ships_filter did not change" do
      admin_membership.update(primary: !admin_membership.primary)

      expect(Updater::FleetMembershipVehiclesSetupJob.jobs.size).to eq(0)
    end
  end

  describe "#remove_fleet_vehicles" do
    it "removes all relevant fleet_vehicles" do
      other_user = create(:user)
      other_user.vehicles.create(model: create(:model), wanted: false)
      new_membership = FleetMembership.create!(fleet_id: fleet.id, user_id: other_user.id, aasm_state: :accepted)

      Updater::FleetMembershipVehiclesSetupJob.drain

      expect(new_membership.fleet.fleet_vehicles.count).to be >= 1

      expect { new_membership.destroy }.to change { new_membership.fleet.fleet_vehicles.count }.by(-1)
    end
  end
end
