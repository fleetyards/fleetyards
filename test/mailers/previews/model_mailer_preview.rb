# frozen_string_literal: true

class ModelMailerPreview < ActionMailer::Preview
  def notify_new
    model = Model.first
    raise 'Please Create a Model' if model.nil?
    ModelMailer.notify_new('foo@bar.de', model)
  end
end
