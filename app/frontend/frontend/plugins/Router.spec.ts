import { describe, expect, it, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import type { RouteLocation } from "vue-router";
import { beforeResolve } from "@/frontend/plugins/Router";
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
      features: [FeatureFlagName.FLEET_SQUADRONS],
      squadronsEnabled: false,
    });

    const redirect = await beforeResolve(
      route(
        {
          feature: FeatureFlagName.FLEET_SQUADRONS,
          featureScope: "fleet",
          fleetSetting: "squadronsEnabled",
        },
        { slug: "the-fleet" },
      ),
    );

    expect(redirect).toEqual({ routeName: "404" });
  });

  it("lets a fleet route through once the fleet has the setting on", async () => {
    queryClient.setQueryData(getFeaturesQueryKey(), []);
    queryClient.setQueryData(getFleetQueryKey("the-fleet"), {
      features: [FeatureFlagName.FLEET_SQUADRONS],
      squadronsEnabled: true,
    });

    const redirect = await beforeResolve(
      route(
        {
          feature: FeatureFlagName.FLEET_SQUADRONS,
          featureScope: "fleet",
          fleetSetting: "squadronsEnabled",
        },
        { slug: "the-fleet" },
      ),
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
