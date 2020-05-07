# frozen_string_literal: true

json.array! @skins, partial: 'api/v1/model_skins/minimal', as: :model_skin
