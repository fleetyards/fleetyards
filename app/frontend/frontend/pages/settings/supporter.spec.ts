import { describe, expect, it, vi, beforeEach } from "vitest";
import { createRouter, createMemoryHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

// BreadCrumbs resolves the route it links to and throws on an unknown name, so
// the crumb target has to exist in whatever router the page is mounted with.
const router = createRouter({
  history: createMemoryHistory(),
  routes: [
    { path: "/", name: "home", component: { template: "<div />" } },
    {
      path: "/settings/profile/",
      name: "settings-profile",
      component: { template: "<div />" },
    },
    {
      path: "/settings/supporter/",
      name: "settings-supporter",
      component: { template: "<div />" },
    },
  ],
});

const claimKey = ref<{ key: string | null } | undefined>(undefined);
const refetch = vi.fn();
const createMutate = vi.fn();
const rotateMutate = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterClaimKey: () => ({
    data: claimKey,
    refetch,
    isPending: ref(false),
  }),
  useCreateMySupporterClaimKey: () => ({
    mutateAsync: createMutate,
    isPending: ref(false),
  }),
  useRotateMySupporterClaimKey: () => ({
    mutateAsync: rotateMutate,
    isPending: ref(false),
  }),
}));

const confirmed = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
    // Run the confirmation straight through, so the action under test is the
    // one that actually fires rather than the dialog opening.
    displayConfirm: ({ onConfirm }: { onConfirm: () => void }) => {
      confirmed();
      onConfirm();
    },
  }),
}));

import SupporterPage from "./supporter.vue";

describe("SettingsSupporterPage", () => {
  beforeEach(() => {
    claimKey.value = { key: null };
    refetch.mockClear();
    createMutate.mockClear();
    rotateMutate.mockClear();
    confirmed.mockClear();
  });

  it("offers to create a key when the account has none", async () => {
    const wrapper = await mountWithDefaults(SupporterPage, {
      plugins: [router],
    });

    expect(wrapper.find("[data-test='create-claim-key']").exists()).toBe(true);
    expect(wrapper.find("[data-test='claim-key']").exists()).toBe(false);
  });

  it("creates a key and reloads it", async () => {
    const wrapper = await mountWithDefaults(SupporterPage, {
      plugins: [router],
    });

    await wrapper.find("[data-test='create-claim-key']").trigger("click");

    expect(createMutate).toHaveBeenCalledOnce();
    expect(refetch).toHaveBeenCalledOnce();
  });

  it("shows the key once there is one, and not the create action", async () => {
    claimKey.value = { key: "FY-7K2M-9QXD" };

    const wrapper = await mountWithDefaults(SupporterPage, {
      plugins: [router],
    });

    expect(
      wrapper.find<HTMLInputElement>("[data-test='claim-key']").element.value,
    ).toBe("FY-7K2M-9QXD");
    expect(wrapper.find("[data-test='create-claim-key']").exists()).toBe(false);
  });

  // Rotation invalidates a key a donor may already have written down, so it
  // must never happen straight off the button.
  it("confirms before rotating", async () => {
    claimKey.value = { key: "FY-7K2M-9QXD" };

    const wrapper = await mountWithDefaults(SupporterPage, {
      plugins: [router],
    });
    await wrapper.find("[data-test='rotate-claim-key']").trigger("click");

    expect(confirmed).toHaveBeenCalledOnce();
    expect(rotateMutate).toHaveBeenCalledOnce();
  });
});
