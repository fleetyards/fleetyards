# frozen_string_literal: true

calliope = CelestialObject.find_or_create_by!(name: 'Calliope')
calliope.update!(hidden: false)
