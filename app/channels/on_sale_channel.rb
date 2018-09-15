# frozen_string_literal: true

class OnSaleChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'on_sale'
  end

  def unsubscribed
    stop_all_streams
  end
end
