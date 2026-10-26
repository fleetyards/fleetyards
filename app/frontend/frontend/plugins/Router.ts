import { useAppStore } from "@/frontend/stores/app";
import { useFleetStore } from "@/frontend/stores/fleet";
import { useSessionStore } from "@/frontend/stores/session";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { APP_UPDATE_NOTICE_TAG } from "@/shared/composables/useAppUpdateNotice";
import { type NavigationFailure, type RouteLocation } from "vue-router";
import { routes } from "@/frontend/pages/routes";
import { setupRouter, type FyRedirectRoute } from "@/shared/plugins/Router";
import { ensureQueryData } from "@/frontend/utils/RouteGuards/queryData";
import { featuresQueryOptions } from "@/frontend/composables/useFeatures";
import { getFleetQueryOptions, type FeatureFlagName } from "@/services/fyApi";

const beforeEach = (to: RouteLocation) => {
  const fleetStore = useFleetStore();
  if (to.name === "fleet-invite" && to.params.token) {
    fleetStore.inviteToken = String(to.params.token);
  }
};

const RELEASE_RELOAD_KEY = "fy-release-reload";

// Long enough for a rollout to finish behind the proxy, short enough that a
// reload which was served the old release is tried again.
const RELEASE_RELOAD_RETRY = 10 * 60 * 1000;

const reloadedRecently = (version: string) => {
  try {
    const last = JSON.parse(
      sessionStorage.getItem(RELEASE_RELOAD_KEY) ?? "null",
    ) as { version: string; at: number } | null;

    return (
      last?.version === version && Date.now() - last.at < RELEASE_RELOAD_RETRY
    );
  } catch {
    return false;
  }
};

const rememberReload = (version: string) => {
  try {
    sessionStorage.setItem(
      RELEASE_RELOAD_KEY,
      JSON.stringify({ version, at: Date.now() }),
    );
  } catch {
    // Without storage the reload still happens, only unguarded.
  }
};

const withoutTrailingSlash = (path: string) => path.replace(/\/+$/, "");

const noticeOnScreen = () =>
  useNotificationsStore().messages.some(
    (message) => message.visible && message.tag !== APP_UPDATE_NOTICE_TAG,
  );

/*
 * A tab left open across a release keeps sending requests shaped by its old
 * bundle, which the API may since refuse. Arriving on another page is when the
 * new release is loaded. After the navigation rather than before it, so a
 * push, a replace and a Back have already left history as they should, and
 * reloading the address bar changes none of it.
 *
 * Not while the path stays put -- typing into a filter only changes the
 * query -- and not with a one-time secret in the query, which a page load would
 * hand to every access log. Not while a notice
 * is up either, since the reload would take a "saved" with it before anyone
 * read it. And not twice in a row for one release, in case the reload is still
 * served the old one.
 */
export const afterEach = (
  to: RouteLocation,
  from: RouteLocation,
  failure?: NavigationFailure | void,
) => {
  const appStore = useAppStore();

  if (
    failure ||
    !appStore.isUpdateAvailable ||
    withoutTrailingSlash(to.path) === withoutTrailingSlash(from.path) ||
    "secret" in to.query ||
    noticeOnScreen() ||
    reloadedRecently(appStore.version)
  ) {
    return;
  }

  rememberReload(appStore.version);

  window.location.reload();
};

// A route behind a flag that is off does not exist for this user: hiding it
// from the nav is not enough, a typed-in URL has to land on the 404 rather than
// render a page whose every request comes back 403.
//
// A fleet route also consults the fleet being navigated to, because a flag can
// be enabled for a fleet rather than for the viewer. Only that fleet — reading
// every fleet the viewer belongs to is what used to show one fleet's features on
// another fleet's page.
// A flag decides whether a fleet may use a feature, and some features then
// still wait for the fleet's admins to switch them on.
const fleetSettingEnabled = async (
  setting: NonNullable<RouteLocation["meta"]["fleetSetting"]>,
  fleetSlug: string,
) => {
  try {
    const fleet = await ensureQueryData(getFleetQueryOptions(fleetSlug));

    return !!fleet?.[setting];
  } catch {
    return true;
  }
};

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

  if (to.meta.fleetSetting && to.params.slug) {
    const settingEnabled = await fleetSettingEnabled(
      to.meta.fleetSetting,
      String(to.params.slug),
    );

    if (!settingEnabled) {
      return {
        routeName: "404",
      };
    }
  }
};

const router = setupRouter({
  beforeResolve,
  beforeEach,
  afterEach,
  routes,
});

export default router;
