stanton = Starsystem.find_or_create_by!(name: 'Stanton')

crusader = Planet.find_or_create_by!(name: 'Crusader', starsystem: stanton)

['Yela', 'Daymar', 'Celin'].each do |moon|
  Planet.find_or_create_by!(name: moon, planet: crusader)
end

hurston = Planet.find_or_create_by!(name: 'Hurston', starsystem: stanton)
arccorp = Planet.find_or_create_by!(name: 'Arccorp', starsystem: stanton)
microtech = Planet.find_or_create_by!(name: 'Microtech', starsystem: stanton)
