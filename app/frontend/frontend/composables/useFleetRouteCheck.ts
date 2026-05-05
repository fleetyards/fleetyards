// Routes that start with "fleet" but don't represent an existing fleet
// (e.g. the new-fleet form, the public invite landing pages). These should
// NOT trigger FleetNav since there's no fleet context.
const NON_FLEET_NAV_ROUTES = new Set([
  "fleet-add",
  "fleet-preview",
  "fleet-invites",
  "fleet-invite",
]);

export const useFleetRouteCheck = () => {
  const route = useRoute();

  const isFleetRoute = computed(() => {
    const name = String(route.name ?? "");
    if (!name.startsWith("fleet")) return false;
    if (NON_FLEET_NAV_ROUTES.has(name)) return false;
    return !!route.params.slug;
  });

  return {
    isFleetRoute,
  };
};
