import { describe, expect, it, vi, beforeEach } from "vitest";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const contributions = ref<unknown[] | undefined>(undefined);
const fleets = ref<unknown[] | undefined>(undefined);
const nominate = vi.fn(() => Promise.resolve({}));
const supported = ref<{ fleet?: { id: string; name: string } } | undefined>(
  undefined,
);
const choose = vi.fn(() => Promise.resolve({}));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useMySupporterContributions: () => ({ data: contributions }),
  useMyFleets: () => ({ data: fleets }),
  useNominateFleetForSupporterContribution: () => ({ mutateAsync: nominate }),
  useMySupportedFleet: () => ({ data: supported }),
  useChooseMySupportedFleet: () => ({ mutateAsync: choose }),
}));

const displaySuccess = vi.fn();
const displayAlert = vi.fn();
// Runs the confirm immediately by default; individual tests take the cancel
// branch by overriding it.
type ConfirmOptions = {
  onConfirm?: () => unknown;
  onClose?: () => unknown;
};

const displayConfirm = vi.fn(
  (options: ConfirmOptions) => void options.onConfirm?.(),
);

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess, displayAlert, displayConfirm }),
}));

const invalidateQueries = vi.fn();

vi.mock("@tanstack/vue-query", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useQueryClient: () => ({ invalidateQueries }),
}));

const featureEnabled = ref(true);

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({
    isFeatureEnabled: () => featureEnabled.value,
  }),
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

// Two selects render once a contribution exists -- the standing choice first,
// then one per donation. Target by name so a test never depends on the order.
const rowSelect = (wrapper: VueWrapper) =>
  wrapper
    .findAllComponents({ name: "BaseSelect" })
    .filter((select) => select.props("name") === "nomination-c-1")[0];

describe("SupporterNomination", () => {
  beforeEach(() => {
    contributions.value = [CONTRIBUTION];
    fleets.value = [FLEET];
    authenticated.value = true;
    featureEnabled.value = true;
    nominate.mockClear();
    choose.mockClear();
    choose.mockResolvedValue({});
    supported.value = undefined;
    nominate.mockResolvedValue({});
    invalidateQueries.mockClear();
    displaySuccess.mockClear();
    displayAlert.mockClear();
    displayConfirm.mockClear();
    displayConfirm.mockImplementation(
      (options: ConfirmOptions) => void options.onConfirm?.(),
    );
  });

  // A visitor who has never donated, or whose donation has not been matched
  // yet, must not be shown a form asking them to pick a fleet.
  // The whole point of the standing choice: answerable before any donation.
  it("offers the choice with no contribution at all", async () => {
    contributions.value = [];

    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination']").exists()).toBe(true);
    expect(wrapper.find("[data-test='supported-fleet']").exists()).toBe(true);
    expect(wrapper.find("[data-test='nomination-c-1']").exists()).toBe(false);
  });

  // Nothing to pick from, so the section would be a dead control.
  it("renders nothing when the account is in no fleet", async () => {
    fleets.value = [];

    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination']").exists()).toBe(false);
  });

  it("saves the standing choice", async () => {
    contributions.value = [];

    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-1");
    await flushPromises();

    expect(choose).toHaveBeenCalledWith({ data: { fleetId: "f-1" } });
  });

  // The premium rollout ships switched off, so nothing about it is visible
  // until the flag is turned on.
  it("renders nothing while the feature flag is off", async () => {
    featureEnabled.value = false;

    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination']").exists()).toBe(false);
  });

  it("lists a linked contribution", async () => {
    const wrapper = await mountWithDefaults(SupporterNomination);

    expect(wrapper.find("[data-test='nomination-c-1']").exists()).toBe(true);
  });

  it("nominates the picked fleet and refreshes the list", async () => {
    const wrapper = await mountWithDefaults(SupporterNomination);

    await rowSelect(wrapper).vm.$emit("update:modelValue", "f-1");
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

    await rowSelect(wrapper).vm.$emit("update:modelValue", "");
    await flushPromises();

    expect(nominate).toHaveBeenCalledWith({
      id: "c-1",
      data: { fleetId: null },
    });
  });

  // Without the guard the second call races the first, and the server applies
  // whichever arrives last with no version check.
  it("ignores a second selection while one is in flight", async () => {
    // Never settles, so the first call is still in flight for the second.
    nominate.mockImplementation(() => new Promise(() => {}));

    const wrapper = await mountWithDefaults(SupporterNomination);
    const select = rowSelect(wrapper);

    await select.vm.$emit("update:modelValue", "f-1");
    await select.vm.$emit("update:modelValue", "");
    await flushPromises();

    expect(nominate).toHaveBeenCalledTimes(1);
    expect(nominate).toHaveBeenCalledWith({
      id: "c-1",
      data: { fleetId: "f-1" },
    });
  });

  // Switching away can take features off the fleet that had them, so it is not
  // a silent change.
  it("confirms before moving support to another fleet", async () => {
    supported.value = { fleet: { id: "f-1", name: "Blue Sun" } };
    fleets.value = [FLEET, { id: "f-2", name: "Red Sun", slug: "red-sun" }];

    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-2");
    await flushPromises();

    expect(displayConfirm).toHaveBeenCalled();
    expect(choose).toHaveBeenCalledWith({ data: { fleetId: "f-2" } });
  });

  it("does not ask when there is nothing to take away", async () => {
    supported.value = undefined;

    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-1");
    await flushPromises();

    expect(displayConfirm).not.toHaveBeenCalled();
    expect(choose).toHaveBeenCalled();
  });

  it("changes nothing when the confirm is dismissed", async () => {
    supported.value = { fleet: { id: "f-1", name: "Blue Sun" } };
    fleets.value = [FLEET, { id: "f-2", name: "Red Sun", slug: "red-sun" }];
    displayConfirm.mockImplementation(
      (options: ConfirmOptions) => void options.onClose?.(),
    );

    const wrapper = await mountWithDefaults(SupporterNomination);

    await wrapper
      .findComponent({ name: "BaseSelect" })
      .vm.$emit("update:modelValue", "f-2");
    await flushPromises();

    expect(choose).not.toHaveBeenCalled();
  });

  it("reports a failure instead of claiming success", async () => {
    nominate.mockRejectedValue(new Error("nope"));

    const wrapper = await mountWithDefaults(SupporterNomination);

    await rowSelect(wrapper).vm.$emit("update:modelValue", "f-1");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalled();
    expect(displaySuccess).not.toHaveBeenCalled();
  });
});
