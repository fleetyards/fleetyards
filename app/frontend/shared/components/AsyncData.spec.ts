import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { ref } from "vue";
import Component from "./AsyncData.vue";
import type { AsyncStatus } from "./AsyncData.types";

// Shaped like an AxiosError so isAxiosError() recognises it. The body matters
// for a 403: the API answers both of its refusals with one, and the code is
// what separates them.
const failedWith = (status: number, data?: unknown) =>
  ({
    isAxiosError: true,
    response: { status, data },
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

// A request that never got an answer: no response, which is what axios reports
// for a device that is offline or a host it could not reach.
function unanswered() {
  return {
    isAxiosError: true,
    code: "ERR_NETWORK",
  } as unknown as AsyncStatus["error"]["value"];
}

const mount = (status: number, data?: unknown) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { asyncStatus: statusOf(failedWith(status, data)) },
  });

describe("AsyncData", () => {
  // The classifier is unit-tested next door, but nothing there would notice a
  // branch written in the wrong order or an import that never landed. These
  // two assert the wiring: the same status, told apart only by the body.
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

  it("reads a rejected request as the client's fault, not an outage", async () => {
    const wrapper = await mount(400);

    expect(wrapper.findComponent({ name: "ClientError" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });

  it("keeps a server failure off the client error screen", async () => {
    const wrapper = await mount(500);

    expect(wrapper.findComponent({ name: "ClientError" }).exists()).toBe(false);
  });

  it("blames the connection, not the server, when nothing answered", async () => {
    const wrapper = await mountWithDefaults<typeof Component>(Component, {
      props: { asyncStatus: statusOf(unanswered()) },
    });

    expect(wrapper.findComponent({ name: "Offline" }).exists()).toBe(true);
    expect(wrapper.findComponent({ name: "ServerError" }).exists()).toBe(false);
  });
});
