# frozen_string_literal: true

clio = CelestialObject.find_or_create_by!(name: 'Clio')
clio.update!(hidden: false)
