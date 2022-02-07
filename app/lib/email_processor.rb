# frozen_string_literal: true

class EmailProcessor
  def initialize(email)
    @email = email
  end

  def process
    user = User.find_by(email: @email.from[:email])

    Message.create(
      subject: @email.subject,
      body: @email.body,
      from: @email.from[:email],
      user_id: user&.id
    )
  end
end
