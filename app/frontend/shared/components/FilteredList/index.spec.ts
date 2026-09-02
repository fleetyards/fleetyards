import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { ref } from "vue";
import Component from "./index.vue";
import type { AsyncStatus } from "@/shared/components/AsyncData.types";

// The filter panel teleports to the off-canvas container the layout provides;
// without it the component cannot render at all.
beforeEach(() => {
  document.body.innerHTML = '<div id="off-canvas-content"></div>';
});

const failedWith = (status: number) =>
  ({
    fetchStatus: ref("idle"),
    isError: ref(true),
    isPending: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    isRefetching: ref(false),
    error: ref({ isAxiosError: true, response: { status } }),
  }) as unknown as AsyncStatus;

// FilteredList is a generic SFC, which is not a plain constructor type; this
// names the props and slots the test uses without reaching for `any`.
const ListComponent = Component as unknown as new (...args: unknown[]) => {
  $props: {
    name: string;
    records: unknown[];
    asyncStatus: AsyncStatus;
    placeholders?: boolean;
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

const mount = (status: number) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [], asyncStatus: failedWith(status) },
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
