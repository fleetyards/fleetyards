# frozen_string_literal: true

lyria = CelestialObject.find_or_create_by!(name: 'Lyria')
lyria.update!(hidden: false)
