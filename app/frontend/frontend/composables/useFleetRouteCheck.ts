export const useFleetRouteCheck = () => {
  const route = useRoute();

  const isFleetRoute = computed(() => {
    return [
      "fleet",
      "fleet-ships",
      "fleet-members",
      "fleet-members-index",
      "fleet-members-invites",
      "fleet-stats",
      "fleet-fleetchart",
      "fleet-logistics",
      "fleet-logistics-root",
      "fleet-logistics-inventories",
      "fleet-logistics-inventory",
      "fleet-settings",
      "fleet-settings-fleet",
      "fleet-settings-membership",
      "fleet-settings-roles",
    ].includes(route.name as string);
  });

  return {
    isFleetRoute,
  };
};
