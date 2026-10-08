import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeAll, beforeEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { defineRule } from "vee-validate";
import { useFleetStore } from "@/frontend/stores/fleet";
import Component from "./add.vue";

const checkFID = vi.fn();

const mutateAsync = vi.fn();

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    checkFID: (...args: unknown[]) => checkFID(...args),
    useCreateFleet: () => ({ mutateAsync }),
  };
});

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useSupportPrompt", () => ({
  useSupportPrompt: () => ({ notifyOnce: vi.fn() }),
}));

const waitForCheck = async () => {
  await new Promise((resolve) => setTimeout(resolve, 350));
  await flushPromises();
};

const mountPage = async (initialState?: Record<string, unknown>) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "fleet-add", component: Component },
      { path: "/fleets/:slug/", name: "fleet", component: Component },
      {
        path: "/fleets/:slug/settings/rsi/",
        name: "fleet-settings-rsi",
        component: Component,
      },
    ],
  });
  await router.push("/");

  const wrapper = await mountWithDefaults(Component, {
    plugins: [router],
    initialState,
  });

  return { wrapper, router };
};

beforeAll(() => {
  ["required", "min", "fidTaken", "alpha_dash", "fleetName"].forEach((rule) =>
    defineRule(rule, () => true),
  );
});

beforeEach(() => {
  checkFID.mockReset();
  mutateAsync.mockReset();
});

describe("FleetAddPage", () => {
  it("offers a temporary FID with the SID when a taken one could be an org's", async () => {
    checkFID.mockResolvedValue({ taken: true, suggestion: "TEST-1" });
    const { wrapper } = await mountPage();

    await wrapper.find('input[name="fid"]').setValue("test");
    await waitForCheck();

    await wrapper
      .find('[data-test="fleet-fid-use-suggestion"]')
      .trigger("click");
    await flushPromises();

    expect(
      (wrapper.find('input[name="fid"]').element as HTMLInputElement).value,
    ).toBe("TEST-1");
    expect(
      (wrapper.find('input[name="rsiSid"]').element as HTMLInputElement).value,
    ).toBe("TEST");
  });

  it("suggests nothing for a free FID", async () => {
    checkFID.mockResolvedValue({ taken: false });
    const { wrapper } = await mountPage();

    await wrapper.find('input[name="fid"]').setValue("free");
    await waitForCheck();

    expect(wrapper.find('[data-test="fleet-fid-suggestion"]').exists()).toBe(
      false,
    );
  });

  it("opens the RSI settings of a fleet created with a SID", async () => {
    mutateAsync.mockResolvedValue({ slug: "test-1", rsiSid: "TEST" });
    checkFID.mockResolvedValue({ taken: false });
    const { wrapper, router } = await mountPage();

    await wrapper.find('input[name="fid"]').setValue("TEST-1");
    await wrapper.find('input[name="name"]').setValue("Real Org");
    await wrapper.find('input[name="rsiSid"]').setValue("TEST");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(router.currentRoute.value.name).toBe("fleet-settings-rsi");
  });

  it("queues the setup tour for the account that created the fleet", async () => {
    mutateAsync.mockResolvedValue({ id: "fleet-1", slug: "test", rsiSid: "" });
    checkFID.mockResolvedValue({ taken: false });
    const { wrapper } = await mountPage({
      session: { currentUser: { id: "user-a" } },
    });
    const fleetStore = useFleetStore();

    await wrapper.find('input[name="fid"]').setValue("TEST");
    await wrapper.find('input[name="name"]').setValue("Test Fleet");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(vi.mocked(fleetStore).queueTour.mock.calls).toEqual([
      ["user-a", "fleet-1"],
    ]);
  });
});
