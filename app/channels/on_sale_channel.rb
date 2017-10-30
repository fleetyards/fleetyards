# frozen_string_literal: true

class OnSaleChannel < ApplicationCable::Channel
  def subscribed
    stream_from "on_sale"
  end
end
