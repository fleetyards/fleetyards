# frozen_string_literal: true

arccorp = CelestialObject.find_or_create_by!(name: 'ArcCorp')
arccorp.update!(hidden: true)
