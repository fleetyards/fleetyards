import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createWebHashHistory } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { usePagination } from "./usePagination";

// Against the real store rather than the testing pinia, whose actions are
// stubs: the point is that removing a saved size reaches the list's request.
const render = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/ships", name: "ships", component: { template: "<div />" } },
    ],
  });
  await router.push({ name: "ships", query });

  const pinia = createPinia();
  const queryClient = new QueryClient();
  const invalidate = vi.spyOn(queryClient, "invalidateQueries");

  let pagination: ReturnType<typeof usePagination> | undefined;

  mount(
    defineComponent({
      setup() {
        pagination = usePagination("ships");

        return () => h("div");
      },
    }),
    {
      global: {
        plugins: [pinia, router, [VueQueryPlugin, { queryClient }]],
      },
    },
  );

  return {
    pagination: pagination!,
    store: usePaginationStore(pinia),
    invalidate,
    router,
  };
};

describe("usePagination", () => {
  it("drops a removed page size and refetches the list", async () => {
    const { pagination, store, invalidate } = await render();

    store.setBykey("ships", 500);
    await flushPromises();
    invalidate.mockClear();

    store.removeByKey("ships");
    await flushPromises();

    expect(pagination.perPage.value).toBeUndefined();
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ["ships"] });
  });

  it("shows the page size a shared link carries", async () => {
    const { pagination, store } = await render({ perPage: "120" });

    store.setBykey("ships", 30);

    expect(pagination.perPage.value).toBe("120");
  });

  it("keeps the visitor's own page size when following a link", async () => {
    const { store } = await render({ perPage: "120" });

    store.setBykey("ships", 30);

    expect(store.findByKey("ships")).toBe(30);
  });

  it("drops the link's page size once the visitor picks one", async () => {
    const { pagination, store, router } = await render({ perPage: "120" });

    pagination.updatePerPage(60);
    await flushPromises();

    expect(store.findByKey("ships")).toBe(60);
    expect(router.currentRoute.value.query).not.toHaveProperty("perPage");
    expect(String(pagination.perPage.value)).toBe("60");
  });
});
