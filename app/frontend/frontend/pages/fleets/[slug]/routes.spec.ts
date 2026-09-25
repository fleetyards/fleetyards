import { createMemoryHistory, createRouter } from "vue-router";
import { routes } from "@/frontend/pages/fleets/[slug]/routes";

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
});
