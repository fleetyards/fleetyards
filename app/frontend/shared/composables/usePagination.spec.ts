import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it, vi } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createWebHashHistory } from "vue-router";
import { AxiosError, type AxiosResponse } from "axios";
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
    queryClient,
  };
};

// What the API answers a size above the list's maximum with.
const refuse = (queryClient: QueryClient, key: unknown[], code: string) =>
  queryClient
    .fetchQuery({
      queryKey: [...key, code],
      retry: false,
      queryFn: () =>
        Promise.reject(
          new AxiosError("refused", "ERR_BAD_REQUEST", undefined, undefined, {
            status: 400,
            data: { code },
          } as AxiosResponse),
        ),
    })
    .catch(() => undefined);

describe("usePagination", () => {
  it("drops a removed page size and refetches the list", async () => {
    const { pagination, store, invalidate } = await render();

    store.setBykey("ships", 240);
    await flushPromises();
    invalidate.mockClear();

    store.removeByKey("ships");
    await flushPromises();

    expect(pagination.perPage.value).toBeUndefined();
    expect(invalidate).toHaveBeenCalledWith({ queryKey: ["ships"] });
  });

  it("shows the page size a shared link carries", async () => {
    const { pagination, store } = await render({ perPage: "144" });

    store.setBykey("ships", 24);

    expect(pagination.perPage.value).toBe("144");
  });

  it("keeps the visitor's own page size when following a link", async () => {
    const { store } = await render({ perPage: "144" });

    store.setBykey("ships", 24);

    expect(store.findByKey("ships")).toBe(24);
  });

  it("drops the link's page size once the visitor picks one", async () => {
    const { pagination, store, router } = await render({ perPage: "144" });

    await pagination.updatePerPage(48);
    await flushPromises();

    expect(store.findByKey("ships")).toBe(48);
    expect(router.currentRoute.value.query).not.toHaveProperty("perPage");
    expect(String(pagination.perPage.value)).toBe("48");
  });

  it("goes back to the first page when the page size changes", async () => {
    const { pagination, router } = await render({ page: "2", q: "x" });

    await pagination.updatePerPage(96);
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ q: "x" });
    expect(pagination.page.value).toBe("1");
  });

  // Otherwise the list asks for the old page at the new size first, which can
  // lie past the end and flash an empty list.
  it("leaves page one before it takes the new size", async () => {
    const { pagination, store, router } = await render({ page: "10" });
    const sizes: unknown[] = [];

    router.afterEach(() => sizes.push(store.findByKey("ships")));

    await pagination.updatePerPage(240);

    expect(sizes).toEqual([undefined]);
    expect(store.findByKey("ships")).toBe(240);
  });

  describe("a size no longer offered", () => {
    it("never requests a linked one, and drops it with its page", async () => {
      const { pagination, store, router } = await render({
        perPage: "30",
        page: "3",
        q: "x",
      });
      store.setBykey("ships", 48);
      await flushPromises();

      expect(pagination.perPage.value).toBe("48");
      expect(router.currentRoute.value.query).toEqual({ q: "x" });
      expect(store.findByKey("ships")).toBe(48);
    });

    it("never requests a saved one, and forgets it", async () => {
      const { pagination, store } = await render();

      store.setBykey("ships", 30);

      expect(pagination.perPage.value).toBeUndefined();

      await flushPromises();

      expect(store.findByKey("ships")).toBeUndefined();
    });

    it("keeps a saved one that is offered", async () => {
      const { pagination, store } = await render();

      store.setBykey("ships", 96);
      await flushPromises();

      expect(pagination.perPage.value).toBe("96");
      expect(store.findByKey("ships")).toBe(96);
    });
  });

  describe("a size above the list's maximum", () => {
    it("drops a linked one the API refused", async () => {
      const { pagination, router, queryClient } = await render({
        perPage: "240",
      });

      await refuse(
        queryClient,
        ["ships", { perPage: "240" }],
        "pagination.max_per_page_reached",
      );
      await flushPromises();

      expect(router.currentRoute.value.query).toEqual({});
      expect(pagination.perPage.value).toBeUndefined();
    });

    it("forgets a saved one the API refused", async () => {
      const { pagination, store, queryClient } = await render();

      store.setBykey("ships", 240);
      await flushPromises();

      await refuse(
        queryClient,
        ["ships", { perPage: "240" }],
        "pagination.max_per_page_reached",
      );
      await flushPromises();

      expect(store.findByKey("ships")).toBeUndefined();
      expect(pagination.perPage.value).toBeUndefined();
    });

    it("keeps the size when something else was refused", async () => {
      const { store, queryClient } = await render();

      store.setBykey("ships", 240);
      await refuse(queryClient, ["ships", {}], "validation_error");
      await flushPromises();

      expect(store.findByKey("ships")).toBe(240);
    });

    it("keeps the size when another list was refused", async () => {
      const { store, queryClient } = await render();

      store.setBykey("ships", 240);
      await refuse(
        queryClient,
        ["images", {}],
        "pagination.max_per_page_reached",
      );
      await flushPromises();

      expect(store.findByKey("ships")).toBe(240);
    });
  });
});
