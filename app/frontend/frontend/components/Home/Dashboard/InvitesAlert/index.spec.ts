import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { computed } from "vue";
import type { FleetMember } from "@/services/fyApi";
import Component from "./index.vue";

let invites: Partial<FleetMember>[] = [];
const accept = vi.fn();
const decline = vi.fn();
const emit = vi.fn();

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit, on: () => () => undefined }),
}));

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useFleetInvites: () => ({ data: computed(() => invites) }),
    useAcceptFleetMembership: () => ({ mutateAsync: accept }),
    useDeclineFleetMembership: () => ({ mutateAsync: decline }),
  };
});

describe("HomeDashboardInvitesAlert", () => {
  beforeEach(() => {
    invites = [];
    accept.mockReset().mockResolvedValue({});
    decline.mockReset().mockResolvedValue({});
    emit.mockClear();
  });

  it("renders nothing without an invite", async () => {
    const subject = await mountWithDefaults(Component);

    expect(subject.find("[data-test='home-invites']").exists()).toBe(false);
  });

  // A request the reader sent is waiting on the fleet, not on them.
  it("leaves out the reader's own join requests", async () => {
    invites = [
      { id: "1", fleetSlug: "rust", fleetName: "Rust", status: "invited" },
      { id: "2", fleetSlug: "nova", fleetName: "Nova", status: "requested" },
    ];

    const subject = await mountWithDefaults(Component);

    expect(subject.findAll(".base-alert")).toHaveLength(1);
  });

  it("accepts an invite and tells the app the fleets changed", async () => {
    invites = [
      { id: "1", fleetSlug: "rust", fleetName: "Rust", status: "invited" },
    ];

    const subject = await mountWithDefaults(Component);

    await subject.findAll(".base-alert .btn")[0].trigger("click");
    await flushPromises();

    expect(accept).toHaveBeenCalledWith({ fleetSlug: "rust" });
    expect(emit).toHaveBeenCalledWith("fleet-update");
  });

  it("declines an invite", async () => {
    invites = [
      { id: "1", fleetSlug: "rust", fleetName: "Rust", status: "invited" },
    ];

    const subject = await mountWithDefaults(Component);

    await subject.findAll(".base-alert .btn")[1].trigger("click");
    await flushPromises();

    expect(decline).toHaveBeenCalledWith({ fleetSlug: "rust" });
    expect(accept).not.toHaveBeenCalled();
  });
});
