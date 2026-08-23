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
// names the props the test uses without reaching for `any`.
const ListComponent = Component as unknown as new (...args: unknown[]) => {
  $props: { name: string; records: unknown[]; asyncStatus: AsyncStatus };
};

const mount = (status: number) =>
  mountWithDefaults<typeof ListComponent>(ListComponent, {
    props: { name: "test-list", records: [], asyncStatus: failedWith(status) },
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
});
