# frozen_string_literal: true

class RoadmapMailerPreview < ActionMailer::Preview
  def notify_admin
    RoadmapMailer.notify_admin
  end
end
