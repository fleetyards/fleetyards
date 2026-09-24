import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createWebHashHistory } from "vue-router";
import { usePaginationStore } from "@/shared/stores/pagination";
import { usePagination } from "./usePagination";

// Against the real store rather than the testing pinia, whose actions are
// stubs: the point is that removing a saved size reaches the list's request.
const render = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/ships", name: "ships", component: { template: "<div />" } },
    ],
  });
  await router.push({ name: "ships" });

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
});
