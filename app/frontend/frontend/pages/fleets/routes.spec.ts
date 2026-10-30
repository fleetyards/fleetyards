import { describe, expect, it } from "vitest";
import {
  createMemoryHistory,
  createRouter,
  type RouteRecordRaw,
} from "vue-router";

const { routes } = await import("@/frontend/pages/fleets/routes");

// The real pages and the fleet's own child routes are beside the point here.
const stubbed = routes.map(({ path, name, meta, redirect }) =>
  redirect
    ? ({ path, name, redirect } as RouteRecordRaw)
    : ({
        path,
        name,
        meta,
        component: { template: "<div />" },
      } as RouteRecordRaw),
);

const buildRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: [{ path: "/fleets/", children: stubbed }],
  });

describe("/fleets/", () => {
  it("opens the directory", async () => {
    const router = buildRouter();

    await router.push("/fleets/");

    expect(router.currentRoute.value.name).toBe("fleet-directory");
  });

  it("resolves /fleets/directory/ before a fleet's slug", async () => {
    const router = buildRouter();

    await router.push("/fleets/directory/");

    expect(router.currentRoute.value.name).toBe("fleet-directory");
  });
});
