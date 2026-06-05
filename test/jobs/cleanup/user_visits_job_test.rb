# frozen_string_literal: true

require "test_helper"

module Cleanup
  class UserVisitsJobTest < ActiveJob::TestCase
    test "#perform deletes all visits and events for the given user" do
      user = create(:user)

      visit_relation = mock("visit_relation")
      event_relation = mock("event_relation")
      user_event_relation = mock("user_event_relation")

      Ahoy::Visit.stubs(:where).with(user_id: user.id).returns(visit_relation)
      visit_relation.stubs(:pluck).with(:id).returns([1, 2])

      Ahoy::Event.stubs(:where).with(visit_id: [1, 2]).returns(event_relation)
      event_relation.expects(:delete_all)

      Ahoy::Visit.stubs(:where).with(id: [1, 2]).returns(visit_relation)
      visit_relation.expects(:delete_all)

      Ahoy::Event.stubs(:where).with(user_id: user.id).returns(user_event_relation)
      user_event_relation.expects(:delete_all)

      ::Cleanup::UserVisitsJob.new.perform(user.id)
    end
  end
end
