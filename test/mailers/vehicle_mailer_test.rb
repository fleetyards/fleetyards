# frozen_string_literal: true

require "test_helper"

class VehicleMailerTest < ActionMailer::TestCase
  setup do
    @vehicle = create(:vehicle)
  end

  test "#on_sale renders the subject with model name" do
    mail = VehicleMailer.on_sale(@vehicle)
    assert_equal I18n.t(:"mailer.vehicle.on_sale.subject", model: @vehicle.model.name), mail.subject
  end

  test "#on_sale sends to the vehicle owner" do
    mail = VehicleMailer.on_sale(@vehicle)
    assert_equal [@vehicle.user.email], mail.to
  end

  test "#on_sale sets the broadcast message stream" do
    mail = VehicleMailer.on_sale(@vehicle)
    assert_equal "broadcast", mail["message_stream"].value
  end

  test "#on_sale renders the body" do
    mail = VehicleMailer.on_sale(@vehicle)
    assert mail.body.encoded.present?
  end
end
