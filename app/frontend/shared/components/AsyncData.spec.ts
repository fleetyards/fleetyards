import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { ref } from "vue";
import Component from "./AsyncData.vue";
import type { AsyncStatus } from "./AsyncData.types";

// Shaped like an AxiosError so isAxiosError() recognises it; only the status
// matters here.
const failedWith = (status: number) =>
  ({
    isAxiosError: true,
    response: { status },
  }) as unknown as AsyncStatus["error"]["value"];

const statusOf = (error: AsyncStatus["error"]["value"]) =>
  ({
    fetchStatus: ref("idle"),
    isError: ref(true),
    isPending: ref(false),
    isLoading: ref(false),
    isFetching: ref(false),
    isRefetching: ref(false),
    error: ref(error),
  }) as unknown as AsyncStatus;

const mount = (status: number) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { asyncStatus: statusOf(failedWith(status)) },
  });

describe("AsyncData", () => {
  it("sends a refused request to the access screen, not the outage one", async () => {
    const wrapper = await mount(403);

    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });

  it("keeps a missing record on the not-found screen", async () => {
    const wrapper = await mount(404);

    expect(wrapper.findComponent({ name: "NotFound" }).exists()).toBe(true);
  });

  it("still reports an actual server failure as one", async () => {
    const wrapper = await mount(500);

    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "Forbidden" }).exists()).toBe(false);
  });
});
