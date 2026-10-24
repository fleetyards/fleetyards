import { createPinia, setActivePinia } from "pinia";
import { beforeEach, describe, expect, it } from "vitest";
import { createMemoryHistory, createRouter } from "vue-router";
import { useRedirectBackStore } from "./redirectBack";

const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/hangar", name: "hangar", component: { render: () => null } },
  ],
});

describe("redirectBack store", () => {
  beforeEach(() => {
    setActivePinia(createPinia());
  });

  it("resolves nothing without a back route", () => {
    expect(useRedirectBackStore().resolveBackRoute(router)).toBeUndefined();
  });

  it("resolves an existing back route and keeps it", () => {
    const store = useRedirectBackStore();
    store.setBackRoute({ name: "hangar" });

    expect(store.resolveBackRoute(router)?.href).toBe("/hangar");
    expect(store.backRoute).toEqual({ name: "hangar" });
  });

  it("drops a back route that no longer exists", () => {
    const store = useRedirectBackStore();
    store.setBackRoute({ name: "renamed-long-ago" });

    expect(store.resolveBackRoute(router)).toBeUndefined();
    expect(store.backRoute).toBeUndefined();
  });
});
