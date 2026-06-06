# frozen_string_literal: true

require "test_helper"

module Notifications
  class NewModelJobTest < ActiveJob::TestCase
    test "#perform sends discord notification and marks model as notified" do
      model = create(:model, notified: false)
      Discord::NewShip.expects(:new).with(model: model).returns(stub(run: true))

      ::Notifications::NewModelJob.new.perform(model.id)

      assert_equal true, model.reload.notified
    end
  end
end
