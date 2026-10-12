import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { defineRule } from "vee-validate";
import { max, required } from "@vee-validate/rules";
import type { Vehicle, VehicleLogEntry } from "@/services/fyApi";

defineRule("required", required);
defineRule("max", max);

const createEntry = vi.fn();
const updateEntry = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useCreateVehicleLogEntry: () => ({
    mutateAsync: createEntry,
    isPending: ref(false),
  }),
  useUpdateVehicleLogEntry: () => ({
    mutateAsync: updateEntry,
    isPending: ref(false),
  }),
}));

// The editor is a whole ProseMirror instance; a textarea is enough to carry
// the text through the form.
vi.mock("@/shared/components/base/FormMarkdownEditor/index.vue", () => ({
  default: {
    name: "FormMarkdownEditor",
    props: ["modelValue", "name", "label"],
    emits: ["update:modelValue"],
    template:
      '<textarea :name="name" :value="modelValue" @input="$emit(\'update:modelValue\', $event.target.value)" />',
  },
}));

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    logEntriesPublicByDefault: false,
    ...overrides,
  }) as Vehicle;

const logEntry: VehicleLogEntry = {
  id: "entry-1",
  title: "Maiden voyage",
  body: "Stanton to Pyro",
  loggedAt: "2026-10-01T16:30:00Z",
  public: false,
  createdAt: "2026-10-01T16:30:00Z",
  updatedAt: "2026-10-01T16:30:00Z",
};

const submit = async (
  wrapper: Awaited<ReturnType<typeof mountWithDefaults>>,
) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

describe("VehicleLogEntryModal", () => {
  beforeEach(() => {
    createEntry.mockReset().mockResolvedValue({});
    updateEntry.mockReset().mockResolvedValue({});
  });

  it("leaves the date to the server when none is picked", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle() },
    });

    await wrapper.find('input[name="title"]').setValue("First flight");
    await submit(wrapper);

    expect(createEntry).toHaveBeenCalledWith({
      vehicleId: "vehicle-1",
      data: {
        title: "First flight",
        body: null,
        loggedAt: undefined,
        public: false,
      },
    });
  });

  it("starts a new entry from the ship's public default", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle({ logEntriesPublicByDefault: true }) },
    });

    await wrapper.find('input[name="title"]').setValue("Shared flight");
    await submit(wrapper);

    expect(createEntry.mock.calls[0][0].data.public).toBe(true);
  });

  it("sends the picked date as an ISO timestamp", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(), logEntry },
    });

    wrapper
      .findComponent({ name: "FormDateTime" })
      .vm.$emit("update:modelValue", "2026-10-02T18:30");
    await submit(wrapper);

    expect(updateEntry).toHaveBeenCalledWith({
      vehicleId: "vehicle-1",
      id: "entry-1",
      data: expect.objectContaining({
        loggedAt: new Date("2026-10-02T18:30").toISOString(),
      }),
    });
  });

  it("does not submit without a title", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle() },
    });

    await submit(wrapper);

    expect(createEntry).not.toHaveBeenCalled();
  });
});
