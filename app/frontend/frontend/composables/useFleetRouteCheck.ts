export const useFleetRouteCheck = () => {
  const route = useRoute();

  const isFleetRoute = computed(() => {
    return [
      "fleet",
      "fleet-ships",
      "fleet-members",
      "fleet-stats",
      "fleet-fleetchart",
      "fleet-settings",
      "fleet-settings-fleet",
      "fleet-settings-membership",
    ].includes(route.name as string);
  });

  return {
    isFleetRoute,
  };
};
