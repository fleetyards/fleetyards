import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
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
      {
        path: "/commodities",
        name: "commodities",
        component: { template: "<div />" },
      },
    ],
  });
  await router.push({ name: "ships", query });

  const pinia = createPinia();

  let pagination: ReturnType<typeof usePagination> | undefined;

  mount(
    defineComponent({
      setup() {
        pagination = usePagination();

        return () => h("div");
      },
    }),
    { global: { plugins: [pinia, router] } },
  );

  await flushPromises();

  return { pagination: pagination!, store: usePaginationStore(pinia), router };
};

describe("usePagination", () => {
  it("shows the page size a shared link carries", async () => {
    const { pagination, store } = await render({ perPage: "144" });

    store.setBykey("ships", 24);

    expect(pagination.perPage.value).toBe("144");
    expect(store.findByKey("ships")).toBe(24);
  });

  it("uses the saved size without a link", async () => {
    const { pagination, store } = await render();

    store.setBykey("ships", 96);

    expect(pagination.perPage.value).toBe("96");
  });

  describe("a size off the shared set", () => {
    it("ignores a linked one, and drops it with its page", async () => {
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

    it("ignores a saved one, and forgets it", async () => {
      const { pagination, store } = await render();

      store.setBykey("ships", 30);

      expect(pagination.perPage.value).toBeUndefined();

      await flushPromises();

      expect(store.findByKey("ships")).toBeUndefined();
    });
  });

  describe("on a page being left", () => {
    it("leaves the next page's sizes alone", async () => {
      const { router } = await render();

      await router.push({ name: "commodities", query: { perPage: "30" } });
      await flushPromises();

      expect(router.currentRoute.value.query).toEqual({ perPage: "30" });
    });

    it("keeps its own size and page for the request", async () => {
      const { pagination, router } = await render({
        perPage: "48",
        page: "2",
      });

      // What the list's request has read before the route moves on.
      expect(pagination.perPage.value).toBe("48");
      expect(pagination.page.value).toBe("2");

      await router.push({ name: "commodities", query: { perPage: "96" } });

      expect(pagination.perPage.value).toBe("48");
      expect(pagination.page.value).toBe("2");
    });
  });

  describe("picking a size", () => {
    it("saves it and goes back to page one", async () => {
      const { pagination, store, router } = await render({
        page: "2",
        q: "x",
      });

      await pagination.updatePerPage(96);

      expect(store.findByKey("ships")).toBe(96);
      expect(router.currentRoute.value.query).toEqual({
        q: "x",
        perPage: "96",
      });
      expect(pagination.page.value).toBe("1");
    });

    // One navigation, so the list never asks for the old page at the new size
    // or the new page at the old one.
    it("moves the size and the page together", async () => {
      const { pagination, store } = await render({ page: "10" });
      store.setBykey("ships", 24);
      await flushPromises();
      const seen: string[] = [];

      watch(
        [pagination.perPage, pagination.page],
        ([perPage, page]) => seen.push(`${perPage}/${page}`),
        { flush: "sync" },
      );

      await pagination.updatePerPage(240);

      expect(seen).toEqual(["240/1"]);
    });

    it("ignores a size off the shared set", async () => {
      const { pagination, store, router } = await render({ page: "3" });

      await pagination.updatePerPage(30);

      expect(store.findByKey("ships")).toBeUndefined();
      expect(router.currentRoute.value.query).toEqual({ page: "3" });
    });

    it("saves nothing when the navigation throws", async () => {
      const { pagination, store, router } = await render();

      router.beforeEach(() => {
        throw new Error("guard failed");
      });

      await expect(pagination.updatePerPage(48)).resolves.toBeUndefined();
      expect(store.findByKey("ships")).toBeUndefined();
    });

    it("saves nothing when the navigation is cancelled", async () => {
      const { pagination, store, router } = await render();

      router.beforeEach(() => false);

      await pagination.updatePerPage(48);

      expect(store.findByKey("ships")).toBeUndefined();
    });
  });
});
