import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { defineComponent, h, ref } from "vue";
import { useRoute } from "vue-router";
import { flushPromises } from "@vue/test-utils";
import Component from "./index.vue";
import { usePaginationStore } from "@/shared/stores/pagination";
import { useFiltersStore } from "@/shared/stores/filters";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";

// The filter panel teleports to the off-canvas container the layout provides;
// without it the component cannot render at all.
beforeEach(() => {
  document.body.innerHTML = '<div id="off-canvas-content"></div>';
});

const failedWith = (status: number, data?: unknown) =>
  ({
    fetchStatus: ref("idle"),
    isError: ref(true),
    isPending: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    isRefetching: ref(false),
    error: ref({ isAxiosError: true, response: { status, data } }),
  }) as unknown as AsyncStatus;

// FilteredList is a generic SFC, which is not a plain constructor type; this
// names the props and slots the test uses without reaching for `any`.
const ListComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    name: string;
    records: unknown[];
    asyncStatus: AsyncStatus;
    placeholders?: boolean;
    viewKeys?: string[];
    isFilterSelected?: boolean;
  };
  $slots: Record<string, unknown>;
};

const loaded = () =>
  ({
    fetchStatus: ref("idle"),
    isError: ref(false),
    isPending: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    isRefetching: ref(false),
    error: ref(undefined),
  }) as unknown as AsyncStatus;

const loading = () =>
  ({
    fetchStatus: ref("fetching"),
    isError: ref(false),
    isPending: ref(true),
    isLoading: ref(true),
    isFetching: ref(true),
    isRefetching: ref(false),
    error: ref(undefined),
  }) as unknown as AsyncStatus;

// Per-page is stored per route name, so the placeholder count is only readable
// from a list that is actually on a named route.
const router = createRouter({
  history: createWebHashHistory(),
  routes: [
    {
      path: "/ships",
      name: "ships",
      component: { template: "<div />" },
    },
    {
      path: "/elsewhere",
      name: "elsewhere",
      component: { template: "<div />" },
    },
  ],
});

const mountOnRoute = async (
  slots: Record<string, string>,
  initialState?: Record<string, unknown>,
) => {
  await router.push({ name: "ships" });

  return mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [], asyncStatus: loading() },
    slots,
    initialState,
    plugins: [router],
  });
};

// A request that never got an answer: no response, which is what axios reports
// for a device that is offline or a host it could not reach.
function unanswered() {
  return {
    fetchStatus: ref("idle"),
    isError: ref(true),
    isPending: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    isRefetching: ref(false),
    error: ref({ isAxiosError: true, code: "ERR_NETWORK" }),
  } as unknown as AsyncStatus;
}

const mount = (status: number, data?: unknown) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: {
      name: "test-list",
      records: [],
      asyncStatus: failedWith(status, data),
    },
  });

const mountWithToolbar = (slots: Record<string, string>) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [{}], asyncStatus: loaded() },
    slots,
  });

const mountWithSlots = (slots: Record<string, () => unknown>) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [], asyncStatus: loaded() },
    slots,
  });

describe("FilteredList", () => {
  // Same status, told apart by the body alone. The unit test on the classifier
  // would not notice these two branches written in the wrong order.
  it("sends an unbought fleet to the supporter block", async () => {
    const wrapper = await mount(403, { code: "subscription_required" });

    expect(
      wrapper.findComponent({ name: "SubscriptionRequired" }).exists(),
    ).toBe(true);
    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(false);
  });

  it("keeps a plain refusal on the access screen", async () => {
    const wrapper = await mount(403, { code: "forbidden" });

    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(true);
    expect(
      wrapper.findComponent({ name: "SubscriptionRequired" }).exists(),
    ).toBe(false);
  });

  it("sends a refused list to the access screen, not the outage one", async () => {
    const wrapper = await mount(403);

    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });

  it("still reports an actual server failure as one", async () => {
    const wrapper = await mount(500);

    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(false);
  });

  it("tells a rejected filter or sort apart from an outage", async () => {
    const wrapper = await mount(400);

    expect(wrapper.findComponent({ name: "ClientError" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });

  it("keeps a server failure off the client error screen", async () => {
    const wrapper = await mount(500);

    expect(wrapper.findComponent({ name: "ClientError" }).exists()).toBe(false);
  });

  it("clears the filter and sort a rejected list was asked for", async () => {
    await router.push({
      name: "ships",
      query: { s: "bogus_asc", manufacturerIn: "rsi", page: "2", tab: "grid" },
    });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400),
        },
        plugins: [router],
      },
    );

    await wrapper.get('[data-test="client-error-reset"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ tab: "grid" });
  });

  it("keeps a saved page size when something else was refused", async () => {
    await router.push({ name: "ships", query: { s: "bogus_asc" } });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400, { code: "validation_error" }),
        },
        initialState: { pagination: { perPage: { ships: 24 } } },
        plugins: [router],
      },
    );

    await wrapper.get('[data-test="client-error-reset"]').trigger("click");
    await flushPromises();

    const store = usePaginationStore();

    expect(vi.mocked(store).removeByKey.mock.calls).toEqual([]);
    expect(router.currentRoute.value.query).toEqual({});
  });

  it("offers no reset for a saved page size the API did not refuse", async () => {
    await router.push({ name: "ships" });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400),
        },
        initialState: { pagination: { perPage: { ships: 24 } } },
        plugins: [router],
      },
    );

    expect(wrapper.find('[data-test="client-error-reset"]').exists()).toBe(
      false,
    );
  });

  // The forms copy the route into local state on mount and never look again,
  // so a reset that only clears the URL leaves the rejected value in the form.
  it("remounts the filter form so it reads the cleared route", async () => {
    await router.push({ name: "ships", query: { qualityGteq: "bogus" } });

    const FilterForm = defineComponent({
      setup() {
        const route = useRoute();
        const form = ref({ ...route.query });

        return () =>
          h("span", { "data-test": "form" }, JSON.stringify(form.value));
      },
    });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400),
        },
        slots: { filter: () => h(FilterForm) },
        plugins: [router],
      },
    );

    // The filter panel is teleported, so it is not inside the wrapper.
    const formText = () =>
      document.querySelector('[data-test="form"]')?.textContent;

    expect(formText()).toContain("bogus");

    await wrapper.get('[data-test="client-error-reset"]').trigger("click");
    await flushPromises();

    expect(formText()).toBe("{}");
  });

  // A Teleport that finds no target on mount never mounts its children, and
  // crashes patching them on the next render.
  it("finds the off-canvas panel that mounts after it", async () => {
    document.body.innerHTML = "";

    const FilterForm = defineComponent({
      props: { count: { type: Number, required: true } },
      setup(props) {
        return () => h("span", { "data-test": "form" }, String(props.count));
      },
    });

    const count = ref(0);

    const Layout = defineComponent({
      setup() {
        return () => [
          h(
            ListComponent,
            {
              name: "test-list",
              records: [],
              asyncStatus: loaded(),
              isFilterSelected: count.value > 0,
            },
            { filter: () => h(FilterForm, { count: count.value }) },
          ),
          h("div", { id: "off-canvas-content" }),
        ];
      },
    });

    const wrapper = await mountWithDefaults(Layout, {
      initialState: { mobile: { mobile: true } },
      attachTo: document.body,
    });

    count.value = 1;
    await flushPromises();

    expect(
      document.querySelector('#off-canvas-content [data-test="form"]')
        ?.textContent,
    ).toBe("1");

    wrapper.unmount();
  });

  it("keeps a list's own view keys through a reset", async () => {
    await router.push({
      name: "ships",
      query: { t: "archive", s: "bogus asc" },
    });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400),
          viewKeys: ["t"],
        },
        plugins: [router],
      },
    );

    await wrapper.get('[data-test="client-error-reset"]').trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ t: "archive" });
  });

  const mountEmptyOn = async (
    query: Record<string, string>,
    viewKeys: string[] = [],
  ) => {
    await router.push({ name: "ships", query });

    return mountWithDefaults<typeof ListComponent>(ListComponent, {
      props: {
        name: "test-list",
        records: [],
        asyncStatus: loaded(),
        viewKeys,
      },
      plugins: [router],
    });
  };

  it("tells the empty box a filter at the top of the URL is one", async () => {
    const wrapper = await mountEmptyOn({ searchCont: "starfarer" });

    expect(
      wrapper.findComponent({ name: "EmptyInfo" }).props("queryPresent"),
    ).toBe(true);
  });

  it("leaves sort and view state out of the empty box's filter", async () => {
    const wrapper = await mountEmptyOn(
      { s: "name asc", tab: "grid", share: "token" },
      ["share"],
    );

    expect(
      wrapper.findComponent({ name: "EmptyInfo" }).props("queryPresent"),
    ).toBe(false);
  });

  it("keeps the list's view keys through the empty box's reset", async () => {
    const wrapper = await mountEmptyOn(
      { searchCont: "starfarer", share: "token", s: "name asc" },
      ["share"],
    );

    const reset = wrapper
      .findComponent({ name: "EmptyActions" })
      .findAll("button")
      .at(-1);
    await reset?.trigger("click");
    await flushPromises();

    expect(router.currentRoute.value.query).toEqual({ share: "token" });
  });

  it("takes the page's own word on whether the list is filtered", async () => {
    await router.push({ name: "ships", query: { searchCont: "starfarer" } });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: loaded(),
          isFilterSelected: false,
        },
        plugins: [router],
      },
    );

    expect(
      wrapper.findComponent({ name: "EmptyInfo" }).props("queryPresent"),
    ).toBe(false);
  });

  it("offers no reset when the route holds nothing to clear", async () => {
    await router.push({ name: "ships", query: { tab: "grid" } });

    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: failedWith(400),
        },
        plugins: [router],
      },
    );

    expect(wrapper.findComponent({ name: "ClientError" }).exists()).toBe(true);
    expect(wrapper.find('[data-test="client-error-reset"]').exists()).toBe(
      false,
    );
  });

  it("blames the connection, not the server, when nothing answered", async () => {
    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: { name: "test-list", records: [], asyncStatus: unanswered() },
      },
    );

    expect(wrapper.findComponent({ name: "Offline" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });

  // A flex line breaks on a child's unwrapped width, so the paginator only
  // wraps on its own - leaving the actions up with the filter button - while it
  // is a child of the toolbar. Nested back inside the right-hand block, the
  // whole block drops instead and a phone spends a row on the filter button
  // alone.
  it("hangs the paginator off the toolbar, not off the actions block", async () => {
    const wrapper = await mountWithToolbar({
      "actions-right": '<button data-test="action">action</button>',
      "pagination-top": '<nav data-test="pager">pager</nav>',
    });

    const pager = wrapper.get('[data-test="pager"]');

    expect(pager.element.parentElement?.className).toContain(
      "filtered-list__pagination-top",
    );
    expect(
      wrapper.get(".filtered-list__pagination-top").element.parentElement
        ?.className,
    ).toContain("filtered-list__actions");
  });

  // The loader is absolutely positioned, so a loading list holds its column
  // open only through the box around it - without one the paginator above the
  // list and the one below it sit on top of each other.
  it("reserves the list's height while it loads", async () => {
    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: { name: "test-list", records: [], asyncStatus: loading() },
        slots: {
          "pagination-top": '<nav data-test="pager-top">pager</nav>',
          "pagination-bottom": '<nav data-test="pager-bottom">pager</nav>',
          default: '<div data-test="records">records</div>',
        },
      },
    );

    expect(wrapper.find('[data-test="records"]').exists()).toBe(false);

    const loader = wrapper.get(".filtered-list__loader");

    expect(loader.findComponent({ name: "LoaderComponent" }).props()).toEqual(
      expect.objectContaining({ loading: true, relative: true }),
    );
  });

  // The count is the reservation: too few placeholders and the page still grows
  // under the reader when the records land.
  it("sizes the placeholder grid from the list's page size", async () => {
    const wrapper = await mountOnRoute(
      { skeleton: '<template #skeleton="{ count }">{{ count }}</template>' },
      { pagination: { perPage: { ships: 20 } } },
    );

    expect(wrapper.get(".filtered-list__loader").text()).toContain("20");
  });

  // A page size is an upper bound, not a promise: a list that has only ever
  // held two records would otherwise reserve a full page of them.
  it("never reserves more than the list has ever held", async () => {
    const wrapper = await mountOnRoute(
      { skeleton: '<template #skeleton="{ count }">{{ count }}</template>' },
      {
        pagination: { perPage: { ships: 20 } },
        listGeometry: { counts: { "test-list": 2 } },
      },
    );

    expect(wrapper.get(".filtered-list__loader").text()).toContain("2");
  });

  it("falls back to the first page-size step before one is picked", async () => {
    const wrapper = await mountOnRoute({
      skeleton: '<template #skeleton="{ count }">{{ count }}</template>',
    });

    expect(wrapper.get(".filtered-list__loader").text()).toContain("10");
  });

  // A table draws its own waiting state out of an empty record set - header,
  // column widths, a page of placeholder rows - so the list hands it the slot
  // rather than replacing it with a spinner.
  it("renders the list itself while it loads when asked to", async () => {
    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: {
          name: "test-list",
          records: [],
          asyncStatus: loading(),
          placeholders: true,
        },
        slots: {
          default:
            '<template #default="{ loading }"><div data-test="list">{{ loading }}</div></template>',
        },
      },
    );

    expect(wrapper.get('[data-test="list"]').text()).toBe("true");
    expect(wrapper.findComponent({ name: "LoaderComponent" }).props()).toEqual(
      expect.objectContaining({ fixed: true }),
    );
  });

  it("leaves a list that did not ask for it with the spinner", async () => {
    const wrapper = await mountWithDefaults<typeof ListComponent>(
      ListComponent,
      {
        props: { name: "test-list", records: [], asyncStatus: loading() },
        slots: { default: '<div data-test="list">records</div>' },
      },
    );

    expect(wrapper.find('[data-test="list"]').exists()).toBe(false);
    expect(wrapper.findComponent({ name: "LoaderComponent" }).props()).toEqual(
      expect.objectContaining({ relative: true }),
    );
  });

  // A list that brings placeholders wants the spinner over them, not centred in
  // a box the placeholders have already filled.
  it("puts the spinner over the placeholders it was given", async () => {
    const wrapper = await mountOnRoute({
      skeleton: '<div data-test="placeholders">cards</div>',
    });

    expect(wrapper.find('[data-test="placeholders"]').exists()).toBe(true);
    expect(wrapper.findComponent({ name: "LoaderComponent" }).props()).toEqual(
      expect.objectContaining({ loading: true, fixed: true }),
    );
  });

  it("renders no block for a slot it was not given", async () => {
    const wrapper = await mountWithToolbar({
      filter: "<div>filter</div>",
    });

    expect(wrapper.find(".filtered-list__actions").exists()).toBe(true);
    expect(wrapper.find(".filtered-list__actions-right").exists()).toBe(false);
    expect(wrapper.find(".filtered-list__pagination-top").exists()).toBe(false);
  });

  it("marks a toolbar that carries nothing but the paginator", async () => {
    const wrapper = await mountWithSlots({
      "pagination-top": () => "pages",
    });

    expect(wrapper.get(".filtered-list").classes()).toContain(
      "filtered-list--pagination-only",
    );
  });

  // The testing pinia stubs every action with a spy, which `spyOn` hands back.
  const mountForFilterActions = async () => {
    await router.push({ name: "ships" });

    await mountWithDefaults<typeof ListComponent>(ListComponent, {
      props: {
        name: "test-list",
        records: [],
        asyncStatus: loaded(),
        viewKeys: ["t"],
      },
      plugins: [router],
    });

    const store = useFiltersStore();

    return {
      saveFilter: vi.spyOn(store, "saveFilter"),
      removeFilter: vi.spyOn(store, "removeFilter"),
    };
  };

  it("saves the filter and sort it is shown with, not its view or page", async () => {
    const { saveFilter } = await mountForFilterActions();

    await router.push({
      name: "ships",
      query: { searchCont: "carrack", s: "name asc", t: "archive", page: "2" },
    });
    await flushPromises();

    expect(saveFilter).toHaveBeenLastCalledWith("/ships", {
      query: { searchCont: "carrack", s: "name asc" },
      viewKeys: ["t"],
    });
  });

  it("forgets the filter once the list is cleared", async () => {
    const { removeFilter } = await mountForFilterActions();

    await router.push({ name: "ships", query: { searchCont: "carrack" } });
    await flushPromises();
    removeFilter.mockClear();

    await router.push({ name: "ships", query: { t: "archive" } });
    await flushPromises();

    expect(removeFilter).toHaveBeenCalledWith("/ships");
  });

  it("leaves its filter alone when the route moves on to another page", async () => {
    const { saveFilter, removeFilter } = await mountForFilterActions();

    await router.push({ name: "ships", query: { searchCont: "carrack" } });
    await flushPromises();
    saveFilter.mockClear();
    removeFilter.mockClear();

    await router.push({ path: "/elsewhere" });
    await flushPromises();

    expect(saveFilter).not.toHaveBeenCalled();
    expect(removeFilter).not.toHaveBeenCalled();
  });

  it("leaves the paginator on the edge once it shares the toolbar", async () => {
    const wrapper = await mountWithSlots({
      "pagination-top": () => "pages",
      "actions-left": () => "action",
    });

    expect(wrapper.get(".filtered-list").classes()).not.toContain(
      "filtered-list--pagination-only",
    );
  });
});
