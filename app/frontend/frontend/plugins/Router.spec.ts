import { describe, expect, it, beforeEach } from "vitest";
import { setActivePinia, createPinia } from "pinia";
import type { RouteLocation } from "vue-router";
import { beforeResolve } from "@/frontend/plugins/Router";
import { queryClient } from "@/frontend/plugins/QueryClient";
import { FeatureFlagName, getFeaturesQueryKey } from "@/services/fyApi";

const route = (meta: RouteLocation["meta"]) =>
  ({
    meta,
    name: "hangar-vehicle-cargo",
    params: {},
    query: {},
  }) as RouteLocation;

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
