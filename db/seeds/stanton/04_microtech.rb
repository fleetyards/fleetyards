# frozen_string_literal: true

microtech = CelestialObject.find_or_create_by!(name: 'microTech')
microtech.update!(hidden: true)
