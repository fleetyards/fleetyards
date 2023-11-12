# frozen_string_literal: true

require "test_helper"

class EmailProcessorTest < ActiveSupport::TestCase
  test "#process" do
    # rubocop:disable Style/OpenStructUse
    email = OpenStruct.new(
      to: [{full: "to_user@email.com", email: "to_user@email.com", token: "to_user", host: "email.com", name: nil}],
      from: {token: "from_user", host: "email.com", email: "from_email@email.com", full: "From User <from_user@email.com>", name: "From User"},
      subject: "email subject",
      body: "Hello!",
      attachments: [
        ActionDispatch::Http::UploadedFile.new(
          filename: "img.png",
          type: "image/png",
          tempfile: File.new("#{__dir__}/../fixtures/files/test.png")
        )
      ]
    )
    # rubocop:enable Style/OpenStructUse

    processor = EmailProcessor.new(email)

    assert_difference %w[Message.count MessageAttachment.count], 1 do
      processor.process
    end
  end
end
