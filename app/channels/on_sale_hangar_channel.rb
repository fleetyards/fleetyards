# frozen_string_literal: true

class OnSaleHangarChannel < ApplicationCable::Channel
  def subscribed
    stream_from "on_sale_#{params[:username]}"
  end

  def unsubscribed
    stop_all_streams
  end
end
