class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    user = User.find_by(email: @email.from[:email])

    Message.create!(
      subject: @email.subject,
      body: @email.body,
      email: @email.from[:email],
      from_raw: @email.from,
      to: @email.to,
      message_attachments: @email.attachments.map do |attachment|
        MessageAttachment.new(payload: attachment.read)
      end,
      user_id: user&.id
    )
  end
end
