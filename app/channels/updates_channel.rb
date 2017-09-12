# encoding: utf-8
# frozen_string_literal: true

class UpdatesChannel < ApplicationCable::Channel
  def subscribed
    stream_from "updates_#{params[:room]}"
  end
end
