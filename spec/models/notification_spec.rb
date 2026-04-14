# frozen_string_literal: true

# == Schema Information
#
# Table name: notifications
#
#  id                :uuid             not null, primary key
#  body              :text
#  expires_at        :datetime         not null
#  icon              :string
#  link              :string
#  notification_type :string           not null
#  read_at           :datetime
#  record_type       :string
#  title             :string           not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  record_id         :uuid
#  user_id           :uuid             not null
#
# Indexes
#
#  index_notifications_on_expires_at              (expires_at)
#  index_notifications_on_notification_type       (notification_type)
#  index_notifications_on_record                  (record_type,record_id)
#  index_notifications_on_user_id_and_created_at  (user_id,created_at DESC)
#  index_notifications_on_user_id_and_read_at     (user_id,read_at)
#
# Foreign Keys
#
#  fk_rails_...  (user_id => users.id)
#
require "rails_helper"

RSpec.describe Notification, type: :model do
  let(:user) { create(:user) }

  # Helper to update existing preferences created by after_create callback
  def set_preference(user, type, **attrs)
    user.notification_preferences.find_by!(notification_type: type).update!(**attrs)
  end

  describe ".notify!" do
    before do
      allow(UserNotificationsChannel).to receive(:broadcast_to)
    end

    describe "app channel" do
      it "creates an unread notification and broadcasts when app is enabled" do
        notification = described_class.notify!(
          user:,
          type: :hangar_create,
          title: "Test"
        )

        expect(notification).to be_persisted
        expect(notification.read_at).to be_nil
        expect(UserNotificationsChannel).to have_received(:broadcast_to).with(user, anything)
      end

      it "creates a read notification without broadcast when app is disabled" do
        set_preference(user, "hangar_create", app: false)

        notification = described_class.notify!(
          user:,
          type: :hangar_create,
          title: "Test"
        )

        expect(notification).to be_persisted
        expect(notification.read_at).to be_present
        expect(UserNotificationsChannel).not_to have_received(:broadcast_to)
      end
    end

    describe "mail channel" do
      context "with model_on_sale type" do
        let(:vehicle) { create(:vehicle, user:) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(VehicleMailer).to receive(:on_sale).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          set_preference(user, "model_on_sale", app: true, mail: true)

          described_class.notify!(
            user:,
            type: :model_on_sale,
            title: "On sale",
            record: vehicle
          )

          expect(VehicleMailer).to have_received(:on_sale).with(vehicle)
        end

        it "does not send email when mail preference is disabled" do
          set_preference(user, "model_on_sale", app: true, mail: false)

          described_class.notify!(
            user:,
            type: :model_on_sale,
            title: "On sale",
            record: vehicle
          )

          expect(VehicleMailer).not_to have_received(:on_sale)
        end
      end

      context "with new_model type" do
        let(:model) { create(:model) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(ModelMailer).to receive(:notify_new).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          set_preference(user, "new_model", mail: true)

          described_class.notify!(
            user:,
            type: :new_model,
            title: "New ship",
            record: model
          )

          expect(ModelMailer).to have_received(:notify_new).with(user.email, model)
        end
      end

      context "with fleet_invite type" do
        let(:fleet) { create(:fleet) }
        let(:membership) { create(:fleet_membership, :invited, fleet:, user:) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(FleetMembershipMailer).to receive(:new_invite).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          described_class.notify!(
            user:,
            type: :fleet_invite,
            title: "Invited",
            record: membership
          )

          expect(FleetMembershipMailer).to have_received(:new_invite).with(user.email, user.username, fleet)
        end

        it "does not send email when mail preference is disabled" do
          set_preference(user, "fleet_invite", mail: false)

          described_class.notify!(
            user:,
            type: :fleet_invite,
            title: "Invited",
            record: membership
          )

          expect(FleetMembershipMailer).not_to have_received(:new_invite)
        end
      end

      context "with fleet_member_requested type" do
        let(:requesting_user) { create(:user) }
        let(:fleet) { create(:fleet, admins: [user]) }
        let(:membership) { create(:fleet_membership, fleet:, user: requesting_user, aasm_state: :requested) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(FleetMembershipMailer).to receive(:member_requested).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          described_class.notify!(
            user:,
            type: :fleet_member_requested,
            title: "Request",
            record: membership
          )

          expect(FleetMembershipMailer).to have_received(:member_requested).with(user.email, requesting_user.username, fleet)
        end
      end

      context "with fleet_member_accepted type" do
        let(:accepted_user) { create(:user) }
        let(:fleet) { create(:fleet, admins: [user]) }
        let(:membership) { create(:fleet_membership, fleet:, user: accepted_user, aasm_state: :accepted) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(FleetMembershipMailer).to receive(:member_accepted).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          described_class.notify!(
            user:,
            type: :fleet_member_accepted,
            title: "Accepted",
            record: membership
          )

          expect(FleetMembershipMailer).to have_received(:member_accepted).with(user.email, accepted_user.username, fleet)
        end
      end

      context "with fleet_request_accepted type" do
        let(:fleet) { create(:fleet) }
        let(:membership) { create(:fleet_membership, fleet:, user:, aasm_state: :accepted) }
        let(:mailer) { double(deliver_later: true) }

        before do
          allow(FleetMembershipMailer).to receive(:fleet_accepted).and_return(mailer)
        end

        it "sends email when mail preference is enabled" do
          described_class.notify!(
            user:,
            type: :fleet_request_accepted,
            title: "Accepted",
            record: membership
          )

          expect(FleetMembershipMailer).to have_received(:fleet_accepted).with(user.email, user.username, fleet)
        end
      end
    end

    describe "app-only types" do
      %i[hangar_create hangar_destroy wishlist_create wishlist_destroy hangar_sync_finished hangar_sync_failed].each do |type|
        it "#{type} only supports app channel" do
          expect(described_class.channels_for(type)).to eq(%i[app])
        end
      end
    end

    describe "app+mail types" do
      %i[model_on_sale new_model fleet_invite fleet_member_requested fleet_member_accepted fleet_request_accepted].each do |type|
        it "#{type} supports app and mail channels" do
          expect(described_class.channels_for(type)).to eq(%i[app mail])
        end
      end
    end

    describe "record association" do
      it "stores the polymorphic record" do
        vehicle = create(:vehicle, user:)
        set_preference(user, "model_on_sale", app: true)

        mailer = double(deliver_later: true)
        allow(VehicleMailer).to receive(:on_sale).and_return(mailer)

        notification = described_class.notify!(
          user:,
          type: :model_on_sale,
          title: "Test",
          record: vehicle
        )

        expect(notification.record).to eq(vehicle)
        expect(notification.record_type).to eq("Vehicle")
      end
    end

    describe "retention" do
      it "sets 7-day retention for hangar types" do
        notification = described_class.notify!(user:, type: :hangar_create, title: "Test")
        expect(notification.expires_at).to be_within(1.second).of(Time.current + 7.days)
      end

      it "sets 30-day retention for sale types" do
        set_preference(user, "model_on_sale", app: true)
        mailer = double(deliver_later: true)
        allow(VehicleMailer).to receive(:on_sale).and_return(mailer)

        notification = described_class.notify!(user:, type: :model_on_sale, title: "Test", record: create(:vehicle, user:))
        expect(notification.expires_at).to be_within(1.second).of(Time.current + 30.days)
      end

      it "sets 90-day retention for sync types" do
        notification = described_class.notify!(user:, type: :hangar_sync_finished, title: "Test")
        expect(notification.expires_at).to be_within(1.second).of(Time.current + 90.days)
      end
    end
  end

  describe ".preference_defaults_for" do
    it "returns opt-in defaults for model_on_sale" do
      expect(described_class.preference_defaults_for(:model_on_sale)).to eq({app: false, mail: false, push: false})
    end

    it "returns mail-enabled defaults for fleet types" do
      expect(described_class.preference_defaults_for(:fleet_invite)).to eq({app: true, mail: true, push: false})
    end

    it "returns standard defaults for app-only types" do
      expect(described_class.preference_defaults_for(:hangar_create)).to eq({app: true, mail: false, push: false})
    end
  end
end
