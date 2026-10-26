import { afterEach, describe, expect, it, beforeEach, vi } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import type { RouteLocation } from "vue-router";
import {
  afterEach as afterNavigation,
  beforeResolve,
} from "@/frontend/plugins/Router";
import { useAppStore } from "@/frontend/stores/app";
import { useNotificationsStore } from "@/shared/stores/notifications";
import { APP_UPDATE_NOTICE_TAG } from "@/shared/composables/useAppUpdateNotice";
import { queryClient } from "@/frontend/plugins/QueryClient";
import {
  FeatureFlagName,
  getFeaturesQueryKey,
  getFleetQueryKey,
} from "@/services/fyApi";

const route = (
  meta: RouteLocation["meta"],
  params: RouteLocation["params"] = {},
) =>
  ({
    meta,
    name: "hangar-vehicle-cargo",
    params,
    query: {},
  }) as RouteLocation;

const fleetRoute = (feature: FeatureFlagName) =>
  route({ feature, featureScope: "fleet" }, { slug: "the-fleet" });

describe("frontend router feature guard", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
    queryClient.clear();
  });

  it("sends a route behind a disabled flag to the 404", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);

    const redirect = await beforeResolve(
      route({ feature: FeatureFlagName.SHIP_INVENTORIES }),
    );

    expect(redirect).toEqual({ routeName: "404" });
  });

  it("lets a route behind an enabled flag through", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), [
      FeatureFlagName.SHIP_INVENTORIES,
    ]);

    const redirect = await beforeResolve(
      route({ feature: FeatureFlagName.SHIP_INVENTORIES }),
    );

    expect(redirect).toBeUndefined();
  });

  it("leaves a route without a flag alone", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);

    const redirect = await beforeResolve(route({}));

    expect(redirect).toBeUndefined();
  });

  it("lets a fleet route through on the fleet's own flag", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), {
      features: [FeatureFlagName.FLEET_LOGISTICS],
    });

    const redirect = await beforeResolve(
      fleetRoute(FeatureFlagName.FLEET_LOGISTICS),
    );

    expect(redirect).toBeUndefined();
  });

  it("sends a fleet route to the 404 when the flag is off for that fleet", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), { features: [] });

    const redirect = await beforeResolve(
      fleetRoute(FeatureFlagName.FLEET_LOGISTICS),
    );

    expect(redirect).toEqual({ routeName: "404" });
  });

  it("sends a fleet route to the 404 while the fleet has the setting off", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), {
      squadronsEnabled: false,
    });

    const redirect = await beforeResolve(
      route({ fleetSetting: "squadronsEnabled" }, { slug: "the-fleet" }),
    );

    expect(redirect).toEqual({ routeName: "404" });
  });

  it("lets a fleet route through once the fleet has the setting on", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), {
      squadronsEnabled: true,
    });

    const redirect = await beforeResolve(
      route({ fleetSetting: "squadronsEnabled" }, { slug: "the-fleet" }),
    );

    expect(redirect).toBeUndefined();
  });

  it("lets a fleet route through on the viewer's own flag", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), [
      FeatureFlagName.FLEET_LOGISTICS,
    ]);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), { features: [] });

    const redirect = await beforeResolve(
      fleetRoute(FeatureFlagName.FLEET_LOGISTICS),
    );

    expect(redirect).toBeUndefined();
  });

  it("ignores the slug of a route that is not fleet-scoped", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);

    const redirect = await beforeResolve(
      route({ feature: FeatureFlagName.SHIP_INVENTORIES }, { slug: "a-model" }),
    );

    expect(redirect).toEqual({ routeName: "404" });
  });

  it("asks an anonymous visitor to sign in before judging the flag", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);

    const redirect = await beforeResolve(
      route({
        feature: FeatureFlagName.SHIP_INVENTORIES,
        needsAuthentication: true,
      }),
    );

    expect(redirect).toEqual({ routeName: "login" });
  });
});

describe("frontend router release reload", () => {
  const at = (path: string, query: RouteLocation["query"] = {}) =>
    ({ path, params: {}, query, meta: {} }) as unknown as RouteLocation;

  const reload = vi.fn();

  beforeEach(() => {
    setActivePinia(createPinia());
    sessionStorage.clear();
    vi.stubGlobal("location", { ...window.location, reload });
  });

  afterEach(() => {
    vi.unstubAllGlobals();
    reload.mockReset();
  });

  const releaseOut = (version = "999.0.0") => {
    useAppStore().version = version;
  };

  it("loads the new release on arriving at another page", () => {
    releaseOut();

    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("stays in the app while the release is current", () => {
    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );

    expect(reload).not.toHaveBeenCalled();
  });

  it("loads the new release on moving from one record to the next", () => {
    releaseOut();

    afterNavigation(
      at("/hangar/ripley/ships/narcissus/"),
      at("/hangar/ripley/ships/nostromo/"),
    );

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("stays in the app when only the query changes", () => {
    releaseOut();

    afterNavigation(
      at("/hangar/ripley/", { page: "2" }),
      at("/hangar/ripley/"),
    );

    expect(reload).not.toHaveBeenCalled();
  });

  it("takes a missing trailing slash for the same page", () => {
    releaseOut();

    afterNavigation(at("/hangar/ripley"), at("/hangar/ripley/"));

    expect(reload).not.toHaveBeenCalled();
  });

  it("loads a filtered list in the new release", () => {
    releaseOut();

    afterNavigation(at("/hangar/ripley/", { name: "nost" }), at("/fleets/"));

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("keeps a one-time secret off the server", () => {
    releaseOut();

    afterNavigation(
      at("/settings/oauth-applications/app/", { secret: "s3cret" }),
      at("/settings/oauth-applications/"),
    );

    expect(reload).not.toHaveBeenCalled();
  });

  it("does not reload after a navigation that failed", () => {
    releaseOut();

    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
      new Error("aborted") as never,
    );

    expect(reload).not.toHaveBeenCalled();
  });

  it("tries again only once a rollout has had time to finish", () => {
    vi.useFakeTimers();
    releaseOut();

    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );
    afterNavigation(at("/fleets/maru/"), at("/hangar/ripley/ships/nostromo/"));

    expect(reload).toHaveBeenCalledTimes(1);

    vi.advanceTimersByTime(11 * 60 * 1000);
    afterNavigation(at("/hangar/ripley/"), at("/fleets/maru/"));

    expect(reload).toHaveBeenCalledTimes(2);
    vi.useRealTimers();
  });

  it("reloads for a newer release straight away", () => {
    releaseOut();
    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );

    releaseOut("1000.0.0");
    afterNavigation(
      at("/hangar/ripley/"),
      at("/hangar/ripley/ships/nostromo/"),
    );

    expect(reload).toHaveBeenCalledTimes(2);
  });

  it("waits while a notice is on screen", () => {
    releaseOut();
    useNotificationsStore().addMessage({
      id: "saved",
      visible: true,
      text: "Tour created",
    } as never);

    afterNavigation(at("/fleets/maru/tours/one/"), at("/fleets/maru/tours/"));

    expect(reload).not.toHaveBeenCalled();
  });

  it("does not wait for the update notice itself", () => {
    releaseOut();
    useNotificationsStore().addMessage({
      id: "update",
      visible: true,
      tag: APP_UPDATE_NOTICE_TAG,
    } as never);

    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );

    expect(reload).toHaveBeenCalledTimes(1);
  });

  it("still reloads where session storage is blocked", () => {
    releaseOut();
    vi.spyOn(Storage.prototype, "setItem").mockImplementation(() => {
      throw new DOMException("blocked", "SecurityError");
    });

    afterNavigation(
      at("/hangar/ripley/ships/nostromo/"),
      at("/hangar/ripley/"),
    );

    expect(reload).toHaveBeenCalledTimes(1);
    vi.restoreAllMocks();
  });
});
