# frozen_string_literal: true

euterpe = CelestialObject.find_or_create_by!(name: 'Euterpe')
euterpe.update!(hidden: false)
