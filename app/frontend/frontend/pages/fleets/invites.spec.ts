import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { useQueryClient } from "@tanstack/vue-query";
import { createRouter, createWebHashHistory } from "vue-router";
import Component from "./invites.vue";

const withdrawMembership = vi.fn();
const displayConfirm = vi.fn();
const displaySuccess = vi.fn();
const displayAlert = vi.fn();

let invites: unknown[] = [];

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");
  const { ref } = await import("vue");

  return {
    ...actual,
    useFleetInvites: () => ({ data: ref(invites), isLoading: ref(false) }),
    useAcceptFleetMembership: () => ({ mutateAsync: vi.fn() }),
    useDeclineFleetMembership: () => ({ mutateAsync: vi.fn() }),
    useWithdrawFleetMembership: () => ({ mutateAsync: withdrawMembership }),
  };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displayConfirm, displaySuccess, displayAlert }),
}));

vi.mock("@tanstack/vue-query", async () => {
  const actual = await vi.importActual<Record<string, unknown>>(
    "@tanstack/vue-query",
  );

  return { ...actual, useQueryClient: vi.fn() };
});

const invalidateQueries = vi.fn();

const mountPage = async (status: string) => {
  invites = [{ id: "1", fleetSlug: "other-fleet", fleetName: "Other", status }];

  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "fleet-invites", component: Component },
      { path: "/fleets/:slug/", name: "fleet", component: Component },
    ],
  });

  await router.push("/");

  const wrapper = await mountWithDefaults(Component, {
    plugins: [router],
  });

  await flushPromises();

  return wrapper;
};

const withdrawBtn = '[data-test="fleet-request-withdraw"]';

describe("FleetInvites", () => {
  beforeEach(() => {
    vi.clearAllMocks();
    vi.mocked(useQueryClient).mockReturnValue({
      invalidateQueries,
    } as unknown as ReturnType<typeof useQueryClient>);
    withdrawMembership.mockResolvedValue(undefined);
    displayConfirm.mockImplementation(({ onConfirm }) => onConfirm());
  });

  it("offers a sent request the way out", async () => {
    const wrapper = await mountPage("requested");

    expect(wrapper.find(withdrawBtn).exists()).toBe(true);
  });

  it("offers an invitation no withdrawal", async () => {
    const wrapper = await mountPage("invited");

    expect(wrapper.find(withdrawBtn).exists()).toBe(false);
  });

  it("leaves the buttons usable when the confirmation is never answered", async () => {
    displayConfirm.mockImplementation(() => {});
    const wrapper = await mountPage("requested");

    await wrapper.find(withdrawBtn).trigger("click");
    await flushPromises();

    expect(wrapper.find(withdrawBtn).attributes("disabled")).toBeUndefined();
  });

  it("withdraws the request and refreshes the fleets", async () => {
    const wrapper = await mountPage("requested");

    await wrapper.find(withdrawBtn).trigger("click");
    await flushPromises();

    expect(withdrawMembership).toHaveBeenCalledWith({
      fleetSlug: "other-fleet",
    });
    expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["fleets"] });
    expect(displaySuccess).toHaveBeenCalled();
    expect(displayAlert).not.toHaveBeenCalled();
  });

  it("says so and re-reads the list when the request could not be withdrawn", async () => {
    withdrawMembership.mockRejectedValue(new Error("nope"));
    vi.spyOn(console, "error").mockImplementation(() => {});
    const wrapper = await mountPage("requested");

    await wrapper.find(withdrawBtn).trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
    expect(invalidateQueries).toHaveBeenCalledWith({ queryKey: ["fleets"] });
  });
});
