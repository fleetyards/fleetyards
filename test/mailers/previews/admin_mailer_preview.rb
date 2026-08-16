# frozen_string_literal: true

class AdminMailerPreview < ActionMailer::Preview
  def weekly
    stats = {
      registrations: 1,
      ships: 2,
      vehicles: 3
    }

    AdminMailer.weekly(stats)
  end

  def notify_block
    AdminMailer.notify_block("https://foo.bar")
  end

  def notify_unblock
    AdminMailer.notify_unblock("https://foo.bar")
  end
end
