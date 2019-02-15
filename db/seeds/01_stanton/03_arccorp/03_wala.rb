# frozen_string_literal: true

wala = CelestialObject.find_or_create_by!(name: 'Wala')
wala.update!(hidden: false)
