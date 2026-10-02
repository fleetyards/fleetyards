import { beforeEach, describe, expect, it, vi } from "vitest";
import {
  createMemoryHistory,
  createRouter,
  type RouteRecordRaw,
} from "vue-router";
import { FeatureFlagName } from "@/services/fyApi";

const ensureQueryData = vi.fn();

vi.mock("@/frontend/utils/RouteGuards/queryData", () => ({
  ensureQueryData: (...args: unknown[]) => ensureQueryData(...args),
}));

const { routes } = await import("@/frontend/pages/fleets/routes");

// The real pages and the fleet's own child routes are beside the point here.
const stubbed = routes.map(
  ({ path, name, meta, beforeEnter }) =>
    ({
      path,
      name,
      meta,
      beforeEnter,
      component: { template: "<div />" },
    }) as RouteRecordRaw,
);

const buildRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/fleets/", children: stubbed }],
  });

beforeEach(() => {
  ensureQueryData.mockReset();
});

describe("/fleets/", () => {
  it("opens the directory once it is rolled out", async () => {
    ensureQueryData.mockResolvedValue([FeatureFlagName.FLEET_DIRECTORY]);
    const router = buildRouter();

    await router.push("/fleets/");

    expect(router.currentRoute.value.name).toBe("fleet-directory");
  });

  it("creates a fleet while the directory is not rolled out", async () => {
    ensureQueryData.mockResolvedValue([]);
    const router = buildRouter();

    await router.push("/fleets/");

    expect(router.currentRoute.value.name).toBe("fleet-add");
  });

  it("creates a fleet when the flags cannot be read", async () => {
    ensureQueryData.mockRejectedValue(new Error("offline"));
    const router = buildRouter();

    await router.push("/fleets/");

    expect(router.currentRoute.value.name).toBe("fleet-add");
  });

  it("resolves /fleets/directory/ before a fleet's slug", async () => {
    const router = buildRouter();

    await router.push("/fleets/directory/");

    expect(router.currentRoute.value.name).toBe("fleet-directory");
    expect(router.currentRoute.value.meta.feature).toBe(
      FeatureFlagName.FLEET_DIRECTORY,
    );
  });
});
