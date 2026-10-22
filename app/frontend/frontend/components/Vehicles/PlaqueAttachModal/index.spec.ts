import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { type PlaqueLines } from "./types";
import { type Model, type Vehicle } from "@/services/fyApi";

const NOW = "2026-10-22T12:00:00Z";

const model = {
  id: "model-1",
  name: "Corsair",
  slug: "corsair",
  media: {},
  playerOwnable: true,
  manufacturer: {
    name: "Drake",
    slug: "drake",
    createdAt: NOW,
    updatedAt: NOW,
  },
} as unknown as Model;

const vehicle = (overrides: Partial<Vehicle> = {}) =>
  ({
    id: "vehicle-1",
    name: "Jolly Roger",
    serial: "JR-0001-AA",
    model,
    createdAt: NOW,
    updatedAt: NOW,
    ...overrides,
  }) as Vehicle;

const lines: PlaqueLines = {
  dedication: "Built rough",
  dedicationVerse: null,
  launchedOn: null,
  launchPort: null,
  launchPortLocationId: null,
  affiliation: null,
  plaqueCaptain: null,
  operationsGroup: null,
  plaqueStyle: "brass",
  plaqueLocale: null,
};

const hangarItems = ref<Vehicle[]>([]);
const hangarFailed = ref(false);
const hangarParams = vi.fn();
const mutateAsync = vi.fn((args: { id: string }) =>
  Promise.resolve(vehicle({ id: args.id })),
);

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useHangar: (params: unknown) => {
    hangarParams(params);
    return {
      data: computed(() => ({ items: hangarItems.value })),
      isLoading: ref(false),
      isError: hangarFailed,
      refetch: vi.fn(),
    };
  },
  useUpdateVehicle: () => ({ mutateAsync, isPending: ref(false) }),
}));

const create = vi.fn(() => Promise.resolve(vehicle({ id: "vehicle-new" })));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    invalidateHangarQueries: vi.fn(),
    invalidateVehiclePage: vi.fn(),
    useCreateMutation: () => ({ mutateAsync: create, isPending: ref(false) }),
  }),
}));

const upload = vi.fn(() => Promise.resolve());

vi.mock("@/frontend/composables/usePlaqueImageUpload", () => ({
  usePlaqueImageUpload: () => ({ capturing: ref(false), upload }),
}));

const displayConfirm = vi.fn((options: { onConfirm: () => void }) =>
  options.onConfirm(),
);
const displaySuccess = vi.fn();
const displayAlert = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displayConfirm,
    displaySuccess,
    displayAlert,
  }),
}));

const mount = (props: { name?: string; serial?: string } = {}) =>
  mountWithDefaults<typeof Component>(Component, {
    props: { model, lines, captain: "torlek", ...props },
  });

describe("VehiclePlaqueAttachModal", () => {
  afterEach(() => {
    hangarItems.value = [];
    hangarFailed.value = false;
    mutateAsync.mockClear();
    create.mockClear();
    upload.mockClear();
    displayConfirm.mockClear();
    displaySuccess.mockClear();
    displayAlert.mockClear();
  });

  it("asks the hangar for every ship of the plaque's model, hidden ones too", async () => {
    await mount();

    expect(hangarParams).toHaveBeenCalledWith(
      expect.objectContaining({
        q: { modelSlugIn: ["corsair"], hiddenByUserEq: "true" },
      }),
    );
  });

  it("offers to add the ship when there is none to put the plaque on", async () => {
    const wrapper = await mount();

    expect(wrapper.find('[data-test="plaque-attach-empty"]').text()).toContain(
      "Corsair",
    );
    expect(wrapper.find('[data-test="plaque-attach-save"]').exists()).toBe(
      false,
    );
    expect(wrapper.find('[data-test="plaque-attach-create"]').exists()).toBe(
      true,
    );
  });

  it("tells a failed hangar request from an empty one", async () => {
    hangarFailed.value = true;
    const wrapper = await mount();

    expect(wrapper.find('[data-test="plaque-attach-error"]').exists()).toBe(
      true,
    );
    expect(wrapper.find('[data-test="plaque-attach-empty"]').exists()).toBe(
      false,
    );
  });

  it("puts the plaque's lines on the only ship there is, and its picture with them", async () => {
    hangarItems.value = [vehicle()];
    const wrapper = await mount();
    await flushPromises();

    await wrapper.find('[data-test="plaque-attach-save"]').trigger("click");
    await flushPromises();

    expect(displayConfirm).not.toHaveBeenCalled();
    expect(mutateAsync).toHaveBeenCalledWith({ id: "vehicle-1", data: lines });
    expect(upload).toHaveBeenCalled();
    expect(displaySuccess).toHaveBeenCalled();
  });

  it("asks before replacing a plaque the ship already has", async () => {
    hangarItems.value = [vehicle({ dedication: "To boldly go" })];
    const wrapper = await mount();
    await flushPromises();

    expect(wrapper.text()).toContain("has a plaque");

    await wrapper.find('[data-test="plaque-attach-save"]').trigger("click");
    await flushPromises();

    expect(displayConfirm).toHaveBeenCalled();
    expect(mutateAsync).toHaveBeenCalled();
  });

  it("waits for a ship to be picked when there are several", async () => {
    hangarItems.value = [
      vehicle(),
      vehicle({ id: "vehicle-2", name: "Kraken" }),
    ];
    const wrapper = await mount();
    await flushPromises();

    expect(
      wrapper.find('[data-test="plaque-attach-save"]').attributes("disabled"),
    ).toBeDefined();

    await wrapper.findAll('input[type="radio"]')[1].setValue(true);
    await wrapper.find('[data-test="plaque-attach-save"]').trigger("click");
    await flushPromises();

    expect(mutateAsync).toHaveBeenCalledWith(
      expect.objectContaining({ id: "vehicle-2" }),
    );
  });

  it("adds the ship when there is none, and puts the plaque on it", async () => {
    const wrapper = await mount({ name: "Jolly Roger", serial: "jr0001aa" });

    await wrapper.find('[data-test="plaque-attach-create"]').trigger("click");
    await flushPromises();

    expect(create).toHaveBeenCalledWith({
      data: { modelId: "model-1", name: "Jolly Roger", serial: "JR-0001-AA" },
    });
    expect(mutateAsync).toHaveBeenCalledWith({
      id: "vehicle-new",
      data: lines,
    });
    expect(upload).toHaveBeenCalled();
  });

  it("leaves a registry the game would not print off the new ship", async () => {
    const wrapper = await mount({ serial: "NCC-1701" });

    await wrapper.find('[data-test="plaque-attach-create"]').trigger("click");
    await flushPromises();

    expect(create).toHaveBeenCalledWith({
      data: { modelId: "model-1", name: null, serial: null },
    });
  });

  it("retries a failed plaque on the ship it added, without adding another", async () => {
    mutateAsync.mockRejectedValueOnce(new Error("422"));
    const wrapper = await mount();

    await wrapper.find('[data-test="plaque-attach-create"]').trigger("click");
    await flushPromises();

    expect(displayAlert).toHaveBeenCalledWith({
      text: expect.stringContaining("in your hangar"),
    });

    await wrapper.find('[data-test="plaque-attach-create"]').trigger("click");
    await flushPromises();

    expect(create).toHaveBeenCalledTimes(1);
    expect(mutateAsync).toHaveBeenLastCalledWith({
      id: "vehicle-new",
      data: lines,
    });
    expect(displaySuccess).toHaveBeenCalled();
  });
});
