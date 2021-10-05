export const isFleetRoute = async function isFleetRoute(routeName) {
  return [
    'fleet',
    'fleet-ships',
    'fleet-members',
    'fleet-stats',
    'fleet-fleetchart',
    'fleet-settings',
    'fleet-settings-fleet',
    'fleet-settings-membership',
  ].includes(routeName)
}

export default isFleetRoute
