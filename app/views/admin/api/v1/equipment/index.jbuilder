# frozen_string_literal: true

json.array! @equipment, partial: 'admin/api/v1/equipment/minimal', as: :equipment
