# encoding: utf-8
# frozen_string_literal: true

class ModelsChannel < ApplicationCable::Channel
  def subscribed
    stream_from 'models'
  end
end
