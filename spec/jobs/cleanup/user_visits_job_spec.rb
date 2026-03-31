# frozen_string_literal: true

require "rails_helper"

RSpec.describe Cleanup::UserVisitsJob do
  describe "#perform" do
    it "deletes all visits and events for the given user" do
      user = create(:user)

      visit_relation = instance_double(ActiveRecord::Relation)
      event_relation = instance_double(ActiveRecord::Relation)
      user_event_relation = instance_double(ActiveRecord::Relation)

      allow(Ahoy::Visit).to receive(:where).with(user_id: user.id).and_return(visit_relation)
      allow(visit_relation).to receive(:pluck).with(:id).and_return([1, 2])

      allow(Ahoy::Event).to receive(:where).with(visit_id: [1, 2]).and_return(event_relation)
      allow(event_relation).to receive(:delete_all)

      allow(Ahoy::Visit).to receive(:where).with(id: [1, 2]).and_return(visit_relation)
      allow(visit_relation).to receive(:delete_all)

      allow(Ahoy::Event).to receive(:where).with(user_id: user.id).and_return(user_event_relation)
      allow(user_event_relation).to receive(:delete_all)

      described_class.new.perform(user.id)

      expect(event_relation).to have_received(:delete_all)
      expect(visit_relation).to have_received(:delete_all)
      expect(user_event_relation).to have_received(:delete_all)
    end
  end
end
