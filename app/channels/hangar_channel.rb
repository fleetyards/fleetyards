# frozen_string_literal: true

class HangarChannel < ApplicationCable::Channel
  def subscribed
    stream_from "hangar_#{params[:username]}"
  end
end
