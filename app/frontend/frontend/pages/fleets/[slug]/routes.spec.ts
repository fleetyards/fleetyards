import { createMemoryHistory, createRouter } from "vue-router";
import { routes } from "@/frontend/pages/fleets/[slug]/routes";
import { FeatureFlagName } from "@/services/fyApi";

const buildRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/fleets/:slug/", children: routes }],
  });

describe("fleet routes", () => {
  describe("the allies list moved into settings", () => {
    it.each([
      ["/fleets/test/allies/", "fleet-settings-allies"],
      ["/fleets/test/allies", "fleet-settings-allies"],
      ["/fleets/test/allies/incoming/", "fleet-settings-allies-incoming"],
      ["/fleets/test/allies/outgoing/", "fleet-settings-allies-outgoing"],
      ["/fleets/test/allies/ignored/", "fleet-settings-allies-ignored"],
    ])("redirects %s to %s", async (path, name) => {
      const router = buildRouter();

      await router.push(path);

      expect(router.currentRoute.value.name).toBe(name);
      expect(router.currentRoute.value.params.slug).toBe("test");
    });
  });

  // Declared on the route, so the guard sends a fleet without the flag to the
  // 404 page instead of the events pages rendering nothing.
  it.each([
    "/fleets/test/events/",
    "/fleets/test/events/some-event/",
    "/fleets/test/events/some-event/payouts/",
  ])("gates %s behind the fleet's mission builder flag", async (path) => {
    const router = buildRouter();

    await router.push(path);

    expect([router.currentRoute.value.meta.feature].flat()).toContain(
      FeatureFlagName.FLEET_MISSION_BUILDER,
    );
    expect(router.currentRoute.value.meta.featureScope).toBe("fleet");
  });
});
