# frozen_string_literal: true

require "test_helper"

class ModelMailerTest < ActionMailer::TestCase
  setup do
    @model = create(:model)
  end

  test "#notify_new renders the subject" do
    mail = ModelMailer.notify_new("user@example.com", @model)
    assert_equal I18n.t(:"mailer.model.new.subject"), mail.subject
  end

  test "#notify_new sends to the correct recipient" do
    mail = ModelMailer.notify_new("user@example.com", @model)
    assert_equal ["user@example.com"], mail.to
  end

  test "#notify_new sets the broadcast message stream" do
    mail = ModelMailer.notify_new("user@example.com", @model)
    assert_equal "broadcast", mail["message_stream"].value
  end

  test "#notify_new renders the body" do
    mail = ModelMailer.notify_new("user@example.com", @model)
    assert mail.body.encoded.present?
  end
end
