import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import type { FleetSquadronRequest } from "@/services/fyApi";
import Component from "./index.vue";

const accept = vi.hoisted(() => vi.fn());
const decline = vi.hoisted(() => vi.fn());
const refetch = vi.hoisted(() => vi.fn());

const requests: FleetSquadronRequest[] = [
  {
    id: "r1",
    createdAt: "2026-10-06T10:00:00Z",
    updatedAt: "2026-10-06T10:00:00Z",
    member: {
      id: "m1",
      username: "hauler",
      status: "accepted",
    },
  } as unknown as FleetSquadronRequest,
];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetSquadronRequests: () => ({
      data: ref(requests),
      isLoading: ref(false),
      refetch,
    }),
    useAcceptFleetSquadronRequest: () => ({ mutateAsync: accept }),
    useDestroyFleetSquadronRequest: () => ({ mutateAsync: decline }),
  };
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  [accept, decline, refetch].forEach((mock) => mock.mockReset());
});

const mount = async () => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { fleetSlug: "maru", squadronSlug: "mining" },
  });

  return wrapper;
};

const ids = {
  fleetSlug: "maru",
  fleetSquadronSlug: "mining",
  username: "hauler",
};

describe("SquadronRequestsList", () => {
  it("accepts a request", async () => {
    const subject = await mount();

    await subject
      .find('[data-test="squadron-request-accept-hauler"]')
      .trigger("click");
    await flushPromises();

    expect(accept).toHaveBeenCalledWith(ids);
    expect(decline).not.toHaveBeenCalled();
    expect(refetch).toHaveBeenCalled();
  });

  it("declines a request", async () => {
    const subject = await mount();

    await subject
      .find('[data-test="squadron-request-decline-hauler"]')
      .trigger("click");
    await flushPromises();

    expect(decline).toHaveBeenCalledWith(ids);
    expect(accept).not.toHaveBeenCalled();
  });
});
