# encoding: utf-8
# frozen_string_literal: true

class OnSaleHangarChannel < ApplicationCable::Channel
  def subscribed
    stream_from "on_sale_#{params[:username]}"
  end
end
