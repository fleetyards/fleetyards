import { beforeEach, describe, expect, it, vi } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import type { HangarPlan, User } from "@/services/fyApi";
import Component from "./index.vue";

defineRule("required", (value: unknown) => !!value || "required");

const me = ref<Partial<User> | undefined>();
const update = vi.fn((_variables: unknown) =>
  Promise.resolve({} as HangarPlan),
);
const create = vi.fn((_variables: unknown) =>
  Promise.resolve({ id: "plan-2" } as HangarPlan),
);
const displayAlert = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMe: () => ({ data: me }),
  useHangarPlans: () => ({ data: ref([]) }),
  useCreateHangarPlan: () => ({ mutateAsync: create }),
  useUpdateHangarPlan: () => ({ mutateAsync: update }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess: vi.fn(), displayAlert }),
}));

vi.mock("vue-router", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useRouter: () => ({ push: vi.fn() }),
}));

const plan = (startingCredit: number | null): HangarPlan =>
  ({
    id: "plan-1",
    name: "Next fleet",
    startingCredit,
    buybackTokens: null,
    vatRate: null,
    syncedBuybackTokens: null,
    syncedStoreCredit: 100,
  }) as HangarPlan;

const creditInput = (wrapper: VueWrapper) =>
  wrapper
    .findAllComponents({ name: "FormInput" })
    .find((input) => input.props("name") === "startingCredit")!;

const useSyncedBtn = (wrapper: VueWrapper) =>
  wrapper.find('[data-test="hangar-plan-use-synced-credit"]');

describe("HangarPlannerPlanModal", () => {
  beforeEach(() => {
    me.value = { rsiStoreCredit: 849.56 };
    update.mockClear();
    create.mockClear();
    displayAlert.mockClear();
  });

  it("shows the synced credit on a new plan", async () => {
    const wrapper = await mountWithDefaults(Component);

    expect(creditInput(wrapper).props("placeholder")).toBe("849.56");
    expect(useSyncedBtn(wrapper).exists()).toBe(false);
  });

  it("prefers the account's credit over the one the plan loaded with", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan: plan(null) },
    });

    expect(creditInput(wrapper).props("placeholder")).toBe("849.56");
  });

  it("offers no reset without a synced credit", async () => {
    me.value = { rsiStoreCredit: null };
    const wrapper = await mountWithDefaults(Component, {
      props: { plan: { ...plan(0), syncedStoreCredit: null } },
    });

    expect(creditInput(wrapper).props("placeholder")).toBe("0");
    expect(useSyncedBtn(wrapper).exists()).toBe(false);
  });

  it("resets a plan's own credit to the synced one", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { plan: plan(0) },
    });

    await useSyncedBtn(wrapper).trigger("click");
    await flushPromises();

    expect(useSyncedBtn(wrapper).exists()).toBe(false);

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(update).toHaveBeenCalledWith({
      id: "plan-1",
      data: expect.objectContaining({ startingCredit: null }),
    });
  });

  it("says why a plan could not be built", async () => {
    const reason =
      "Your wishlist has 501 ships, but a plan holds at most 500. Remove some from the wishlist, or start the plan empty.";
    create.mockRejectedValueOnce({
      isAxiosError: true,
      response: {
        data: {
          code: "validation_error.hangar_plans.create",
          errors: [
            {
              attribute: "base",
              messages: [{ code: "wishlist_too_large", message: reason }],
            },
          ],
        },
      },
    });
    const wrapper = await mountWithDefaults(Component);

    await wrapper
      .findAllComponents({ name: "FormInput" })
      .find((input) => input.props("name") === "name")!
      .find("input")
      .setValue("From the wishlist");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(create).toHaveBeenCalled();
    expect(displayAlert).toHaveBeenCalledWith({ text: reason });
  });
});
