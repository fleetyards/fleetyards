import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { type RouteLocation } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { featuresQueryOptions } from "@/frontend/composables/useFeatures";
import { getFleetQueryOptions, type FeatureFlagName } from "@/services/fyApi";
import type { QueryFunction, UseQueryOptions } from "@tanstack/vue-query";

const beforeEach = (to: RouteLocation) => {
  const fleetStore = useFleetStore();
  if (to.name === "fleet-invite" && to.params.token) {
    fleetStore.inviteToken = String(to.params.token);
  }

  const appStore = useAppStore();
  // check if update is available
  if (
    appStore.isUpdateAvailable &&
    Object.keys(to.query).length === 0 &&
    to.query.constructor === Object &&
    Object.keys(to.params).length === 0 &&
    to.params.constructor === Object
  ) {
    window.location.href = to.path;
    return;
  }
};

// The generated options are typed for `useQuery`, where `queryFn` carries
// vue-query's widened stand-in for `skipToken` — a bare `symbol` the query
// client's own options reject. Only the key and the fetcher decide what
// `ensureQueryData` returns; the rest of the options still apply at runtime.
const ensureQueryData = <TData, TError>(
  options: UseQueryOptions<TData, TError, TData>,
): Promise<TData> =>
  queryClient.ensureQueryData(
    options as unknown as {
      queryKey: readonly unknown[];
      queryFn: QueryFunction<TData>;
    },
  );

// A route behind a flag that is off does not exist for this user: hiding it
// from the nav is not enough, a typed-in URL has to land on the 404 rather than
// render a page whose every request comes back 403.
//
// A fleet route also consults the fleet being navigated to, because a flag can
// be enabled for a fleet rather than for the viewer. Only that fleet — reading
// every fleet the viewer belongs to is what used to show one fleet's features on
// another fleet's page.
const featureEnabled = async (feature: FeatureFlagName, fleetSlug?: string) => {
  try {
    const [features, fleet] = await Promise.all([
      ensureQueryData(featuresQueryOptions()),
      fleetSlug ? ensureQueryData(getFleetQueryOptions(fleetSlug)) : undefined,
    ]);

    return (
      !!features?.includes(feature) || !!fleet?.features?.includes(feature)
    );
  } catch {
    // The endpoint is also what the nav reads, so a failure here is already
    // visible. Let the navigation through and leave the API as the real gate
    // rather than 404-ing pages the user may well have access to.
    return true;
  }
};

export const beforeResolve = async (
  to: RouteLocation,
): Promise<FyRedirectRoute | undefined> => {
  const sessionStore = useSessionStore();

  if (to.meta.needsAuthentication && !sessionStore.isAuthenticated) {
    const redirectBackStore = useRedirectBackStore();
    redirectBackStore.setBackRoute(to);

    return {
      routeName: "login",
    };
  }

  if (to.meta.needsNoAuthentication && sessionStore.isAuthenticated) {
    return {
      routeName: "home",
    };
  }

  // After the session checks: flags are read per user, so signing in first is
  // what makes the answer meaningful.
  const fleetSlug =
    to.meta.featureScope === "fleet" ? String(to.params.slug) : undefined;

  // A route can stack flags -- a fleet's tours need the tours feature *and* the
  // fleet one -- and every one of them has to be on.
  const features = to.meta.feature ? [to.meta.feature].flat() : [];

  const allowed = await Promise.all(
    features.map((feature) => featureEnabled(feature, fleetSlug)),
  );

  if (allowed.some((enabled) => !enabled)) {
    return {
      routeName: "404",
    };
  }
};

const router = setupRouter({
  beforeResolve,
  beforeEach,
  routes,
});

export default router;
