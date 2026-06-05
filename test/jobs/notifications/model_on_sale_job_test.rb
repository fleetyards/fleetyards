# frozen_string_literal: true

require "test_helper"

module Notifications
  class ModelOnSaleJobTest < ActiveJob::TestCase
    setup do
      @model = create(:model, pledge_price: 100)
    end

    test "#perform sends discord notification when model has pledge price" do
      Discord::ShipOnSale.expects(:new).with(model: @model).returns(stub(run: true))

      ::Notifications::ModelOnSaleJob.new.perform(@model.id)
    end

    test "#perform does not send discord notification when pledge price is nil" do
      @model.update_column(:pledge_price, nil)

      Discord::ShipOnSale.expects(:new).never

      ::Notifications::ModelOnSaleJob.new.perform(@model.id)
    end

    test "#perform notifies users with wanted vehicles that have sale_notify enabled" do
      user = create(:user, sale_notify: true)
      vehicle = create(:vehicle, model: @model, user: user, sale_notify: true, wanted: true, loaner: false, notify: true)

      Discord::ShipOnSale.stubs(:new).returns(stub(run: true))
      OnSaleHangarChannel.expects(:broadcast_to).at_least_once
      VehicleMailer.expects(:on_sale).with(vehicle).returns(stub(deliver_later: true))

      ::Notifications::ModelOnSaleJob.new.perform(@model.id)

      notification = Notification.find_by(user: user, notification_type: "model_on_sale")
      assert notification.present?
      assert_equal vehicle, notification.record
    end
  end
end
