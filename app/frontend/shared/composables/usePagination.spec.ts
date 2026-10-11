import { flushPromises, mount } from "@vue/test-utils";
import { describe, expect, it } from "vitest";
import { QueryClient, VueQueryPlugin } from "@tanstack/vue-query";
import type { QueryKey } from "@tanstack/vue-query";
import { createPinia } from "pinia";
import { createRouter, createWebHashHistory } from "vue-router";
import { AxiosError, type AxiosResponse } from "axios";
import type { Ref } from "vue";
import { usePaginationStore } from "@/shared/stores/pagination";
import { usePagination } from "./usePagination";

// Against the real store rather than the testing pinia, whose actions are
// stubs: the point is that removing a saved size reaches the list's request.
const render = async (
  query: Record<string, string> = {},
  {
    queryKey = ["ships"],
    seed = () => {},
  }: {
    queryKey?: QueryKey | Ref<QueryKey>;
    seed?: (queryClient: QueryClient) => void;
  } = {},
) => {
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
  const queryClient = new QueryClient();
  seed(queryClient);

  let pagination: ReturnType<typeof usePagination> | undefined;

  mount(
    defineComponent({
      setup() {
        pagination = usePagination(queryKey);

        return () => h("div");
      },
    }),
    {
      global: {
        plugins: [pinia, router, [VueQueryPlugin, { queryClient }]],
      },
    },
  );

  await flushPromises();

  return {
    pagination: pagination!,
    store: usePaginationStore(pinia),
    router,
    queryClient,
  };
};

// An answer for a list, naming the sizes it offers.
const answer = (steps: (number | string)[]) => ({
  items: [],
  meta: { pagination: { perPageSteps: steps } },
});

// What the API answers a size above the list's maximum with.
const refuse = (queryClient: QueryClient, queryKey: QueryKey) =>
  queryClient
    .fetchQuery({
      queryKey,
      retry: false,
      queryFn: () =>
        Promise.reject(
          new AxiosError("refused", "ERR_BAD_REQUEST", undefined, undefined, {
            status: 400,
            data: { code: "pagination.max_per_page_reached" },
          } as AxiosResponse),
        ),
    })
    .catch(() => undefined);

describe("usePagination", () => {
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
    expect(pagination.perPage.value).toBe("48");
  });

  it("goes back to the first page when the page size changes", async () => {
    const { pagination, router } = await render({ page: "2", q: "x" });

    await pagination.updatePerPage(96);
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ q: "x" });
    expect(pagination.page.value).toBe("1");
  });

  // Otherwise the list asks for the old page at the new size, or the new page
  // at the old size, before it settles.
  it("moves the size and the page together", async () => {
    const { pagination, store } = await render({ page: "10" });
    const seen: string[] = [];

    watch(
      [pagination.perPage, pagination.page],
      ([perPage, page]) => seen.push(`${perPage}/${page}`),
      { flush: "sync" },
    );

    store.setBykey("ships", 24);
    seen.length = 0;

    await pagination.updatePerPage(240);
    await flushPromises();

    expect(seen).toEqual(["240/1"]);
    expect(store.findByKey("ships")).toBe(240);
  });

  it("ignores a picked size the list does not offer", async () => {
    const { pagination, store } = await render(
      { page: "3" },
      {
        seed: (client) => client.setQueryData(["ships"], answer([12, 24, 48])),
      },
    );
    await pagination.updatePerPage(240);
    await flushPromises();

    expect(store.findByKey("ships")).toBeUndefined();
    expect(pagination.page.value).toBe("3");
  });

  describe("a size off the shared set", () => {
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

  describe("a size this list does not offer", () => {
    it("drops a linked one once the list's answer names its sizes", async () => {
      const { pagination, router, queryClient } = await render({
        perPage: "all",
      });

      expect(pagination.perPage.value).toBe("all");

      queryClient.setQueryData(["ships"], answer([12, 24, 48, 96]));
      await flushPromises();

      expect(router.currentRoute.value.query).toEqual({});
      expect(pagination.perPage.value).toBeUndefined();
    });

    it("keeps one the list offers", async () => {
      const { pagination, queryClient } = await render({ perPage: "all" });

      queryClient.setQueryData(["ships"], answer([12, 24, "all"]));
      await flushPromises();

      expect(pagination.perPage.value).toBe("all");
    });

    it("ignores the sizes another list names", async () => {
      const { pagination, queryClient } = await render({ perPage: "240" });

      queryClient.setQueryData(["ships", "x", "squadrons"], answer([12, 24]));
      await flushPromises();

      expect(pagination.perPage.value).toBe("240");
    });

    it("reads the steps of the list it shows now, not the last one", async () => {
      const queryKey = ref<QueryKey>(["shops", "a", "items"]);
      const { pagination, store, queryClient } = await render(
        {},
        {
          queryKey,
          seed: (client) =>
            client.setQueryData(["shops", "a", "items"], answer([12, 24])),
        },
      );

      queryKey.value = ["shops", "b", "items"];
      store.setBykey("ships", 96);
      await flushPromises();

      expect(store.findByKey("ships")).toBe(96);
      expect(pagination.perPage.value).toBe("96");

      queryClient.setQueryData(["shops", "b", "items"], answer([12, 24, 96]));
      await flushPromises();

      expect(store.findByKey("ships")).toBe(96);
    });

    it("leaves the next page's sizes alone while it leaves", async () => {
      const { router, queryClient } = await render(
        {},
        {
          seed: (client) => client.setQueryData(["ships"], answer([12, 24])),
        },
      );

      await router.push({ name: "commodities", query: { perPage: "96" } });
      queryClient.setQueryData(["ships"], answer([12]));
      await flushPromises();

      expect(router.currentRoute.value.query).toEqual({ perPage: "96" });
    });
  });

  describe("a size the API refuses as above the maximum", () => {
    it("drops a linked one", async () => {
      const { pagination, router, queryClient } = await render({
        perPage: "240",
      });

      await refuse(queryClient, ["ships"]);
      await flushPromises();

      expect(router.currentRoute.value.query).toEqual({});
      expect(pagination.perPage.value).toBeUndefined();
    });

    it("forgets a saved one", async () => {
      const { pagination, store, queryClient } = await render();

      store.setBykey("ships", 240);
      await flushPromises();

      await refuse(queryClient, ["ships"]);
      await flushPromises();

      expect(store.findByKey("ships")).toBeUndefined();
      expect(pagination.perPage.value).toBeUndefined();
    });

    it("blames the saved size when the link was never requested", async () => {
      const { store, router, queryClient } = await render();

      store.setBykey("ships", 240);
      await router.replace({ query: { perPage: "30" } });
      await refuse(queryClient, ["ships"]);
      await flushPromises();

      expect(store.findByKey("ships")).toBeUndefined();
    });

    it("keeps the size when another request to the endpoint was refused", async () => {
      const { store, queryClient } = await render();

      store.setBykey("ships", 240);
      await refuse(queryClient, ["ships", { perPage: "all" }]);
      await refuse(queryClient, ["ships", "x", "squadrons"]);
      await flushPromises();

      expect(store.findByKey("ships")).toBe(240);
    });
  });
});
