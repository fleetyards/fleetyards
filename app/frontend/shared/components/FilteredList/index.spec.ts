import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it } from "vitest";
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
  $props: { name: string; records: unknown[]; asyncStatus: AsyncStatus };
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

const mount = (status: number) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [], asyncStatus: failedWith(status) },
  });

const mountWithToolbar = (slots: Record<string, string>) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [{}], asyncStatus: loaded() },
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

  it("renders no block for a slot it was not given", async () => {
    const wrapper = await mountWithToolbar({
      filter: "<div>filter</div>",
    });

    expect(wrapper.find(".filtered-list__actions").exists()).toBe(true);
    expect(wrapper.find(".filtered-list__actions-right").exists()).toBe(false);
    expect(wrapper.find(".filtered-list__pagination-top").exists()).toBe(false);
  });
});
