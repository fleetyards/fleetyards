import { describe, expect, it, vi, beforeEach } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const contributions = ref<unknown[] | undefined>(undefined);
const fleets = ref<unknown[] | undefined>(undefined);
const nominate = vi.fn(() => Promise.resolve({}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterContributions: () => ({ data: contributions }),
  useMyFleets: () => ({ data: fleets }),
  useNominateFleetForSupporterContribution: () => ({ mutateAsync: nominate }),
}));

const displaySuccess = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert }),
}));

const invalidateQueries = vi.fn();

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useQueryClient: () => ({ invalidateQueries }),
}));

const authenticated = ref(true);

vi.mock("@/frontend/stores/session", () => ({
  useSessionStore: () => ({
    get isAuthenticated() {
      return authenticated.value;
    },
  }),
}));

import SupporterNomination from "./index.vue";

const CONTRIBUTION = {
  id: "c-1",
  amountCents: 500,
  currency: "EUR",
  startedAt: "2026-09-01",
  recurring: true,
};

const FLEET = { id: "f-1", name: "Blue Sun", slug: "blue-sun" };

describe("SupporterNomination", () => {
  beforeEach(() => {
    contributions.value = [CONTRIBUTION];
    fleets.value = [FLEET];
    authenticated.value = true;
    nominate.mockClear();
    nominate.mockResolvedValue({});
    invalidateQueries.mockClear();
    displaySuccess.mockClear();
    displayAlert.mockClear();
  });

  // A visitor who has never donated, or whose donation has not been matched
  // yet, must not be shown a form asking them to pick a fleet.
  it("renders nothing without a linked contribution", async () => {
    contributions.value = [];

    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination']").exists()).toBe(false);
  });

  it("lists a linked contribution", async () => {
    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination-c-1']").exists()).toBe(true);
  });

  it("nominates the picked fleet and refreshes the list", async () => {
    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-1");
    await flushPromises();

    expect(nominate).toHaveBeenCalledWith({
      id: "c-1",
      data: { fleetId: "f-1" },
    });
    expect(invalidateQueries).toHaveBeenCalled();
    expect(displaySuccess).toHaveBeenCalled();
  });

  // Clearing has to reach the API as an explicit null: an absent key would
  // leave the nomination where it was.
  it("clears the nomination with an explicit null", async () => {
    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "");
    await flushPromises();

    expect(nominate).toHaveBeenCalledWith({
      id: "c-1",
      data: { fleetId: null },
    });
  });

  it("reports a failure instead of claiming success", async () => {
    nominate.mockRejectedValue(new Error("nope"));

    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-1");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
  });
});
