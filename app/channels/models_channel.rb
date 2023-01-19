# frozen_string_literal: true

class ModelsChannel < ApplicationCable::Channel
  def subscribed
    stream_from "models"
  end

  def unsubscribed
    stop_all_streams
  end
end
