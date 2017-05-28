# encoding: utf-8
# frozen_string_literal: true

json.array! @images, partial: 'api/v1/images/with_ship', as: :image
