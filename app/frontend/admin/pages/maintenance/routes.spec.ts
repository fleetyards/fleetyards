import {
  createMemoryHistory,
  createRouter,
  type RouteRecordRaw,
} from "vue-router";
import { routes } from "@/admin/pages/maintenance/routes";

const Stub = { render: () => null };

const buildRouter = () =>
  createRouter({
    history: createMemoryHistory(),
    routes: routes.map((route): RouteRecordRaw =>
      route.redirect
        ? route
        : { path: route.path, name: route.name, component: Stub },
    ),
  });

describe("maintenance routes", () => {
  it.each([
    ["/maintenance/imports", "/imports/"],
    ["/maintenance/imports/42", "/imports/42"],
    ["/maintenance/rsi-api-status", "/rsi-api-status/"],
  ])("sends %s on to %s", async (from, to) => {
    const router = buildRouter();

    await router.push(from);

    expect(router.currentRoute.value.matched).not.toHaveLength(0);
    expect(router.currentRoute.value.path.replace(/\/$/, "")).toBe(
      to.replace(/\/$/, ""),
    );
  });

  it("keeps the query", async () => {
    const router = buildRouter();

    await router.push("/maintenance/imports?page=2");

    expect(router.currentRoute.value.query).toEqual({ page: "2" });
  });
});
