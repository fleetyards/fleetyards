import { describe, expect, it, vi } from "vitest";
import { flushPromises, mount } from "@vue/test-utils";

const createMutation = vi.fn(() => Promise.resolve({ slug: "job-1" }));
const updateMutation = vi.fn(() => Promise.resolve({ slug: "job-1" }));

const destinations = vi.hoisted(() => ({
  value: [] as Record<string, unknown>[],
}));
const destinationParams = vi.hoisted(() => ({
  value: undefined as { value: Record<string, unknown> } | undefined,
}));

// Mocked as a module, not stubbed at mount: the real one reaches HoloViewer and
// pulls three.js in, which does not resolve under vitest.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: {
    name: "FormFileInput",
    props: [
      "modelValue",
      "file",
      "previewSrc",
      "presetValue",
      "presetCatalogue",
      "presetGroup",
    ],
    emits: ["update:modelValue", "update:presetValue"],
    template: "<div />",
  },
}));

vi.mock("@/services/fyApi", () => ({
  FleetContractKindEnum: {
    TRANSPORT: "transport",
    PROCUREMENT: "procurement",
    CRAFTING: "crafting",
  },
  FleetContractDestinationHolderEnum: { FLEET: "fleet", USER: "user" },
  useFleetInventories: () => ({ data: { value: { items: [] } } }),
  useFleetContractDestinations: (
    _fleetSlug: unknown,
    params: { value: Record<string, unknown> },
  ) => {
    destinationParams.value = params;
    return { data: destinations };
  },
  useCreateFleetContract: () => ({ mutateAsync: createMutation }),
  useUpdateFleetContract: () => ({ mutateAsync: updateMutation }),
}));

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, params?: Record<string, string>) =>
      params ? `${key}(${Object.values(params).join(",")})` : key,
  }),
}));

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({
    displaySuccess: vi.fn(),
    displayAlert: vi.fn(),
  }),
}));

vi.mock("@/shared/composables/useComlink", () => ({
  useComlink: () => ({ emit: vi.fn(), on: vi.fn() }),
}));

vi.mock("vue-router", () => ({ useRouter: () => ({ push: vi.fn() }) }));

vi.mock("@/frontend/composables/useSquadronVisibility", () => ({
  useSquadronVisibility: () => ({
    withSquadronChoice: <T>(options: T[]) => options,
  }),
}));

import ContractForm from "./index.vue";

const FLEET = { slug: "black-sun", name: "Black Sun" };

const mountForm = (contract?: Record<string, unknown>) =>
  mount(ContractForm, {
    props: { fleet: FLEET as never, contract: contract as never },
    global: {
      stubs: {
        FormTabs: { template: "<div><slot /></div>" },
        FormTab: { template: "<div><slot /></div>" },
        FormActions: true,
        FormInput: true,
        FormTextarea: true,
        FormToggle: true,
        FormDateTime: true,
        BaseSelect: true,
      },
    },
  });

const field = (wrapper: ReturnType<typeof mountForm>) =>
  wrapper.getComponent({ name: "FormFileInput" });

const vm = (wrapper: ReturnType<typeof mountForm>) =>
  wrapper.vm as unknown as {
    coverImage: string | null | undefined;
    coverImagePreset: string | null;
    kind: string;
  };

const SAVED_COVER = {
  slug: "job-1",
  kind: "transport",
  coverImage: { url: "/saved.png", smallUrl: "/saved-small.png" },
  coverImagePreset: null,
};

describe("ContractForm cover", () => {
  /*
   * The field owns the choosing now -- it draws the preset where the picture
   * goes and clears whatever it is replacing. What is left here is the wiring:
   * whatever it says has to reach the payload, because `useContractCover`
   * prefers an attachment over any preset and a cover left attached would make
   * choosing one look like it did nothing.
   */
  it("detaches a saved cover when the field says a preset replaced it", async () => {
    const wrapper = mountForm(SAVED_COVER);
    const input = field(wrapper);

    await input.vm.$emit("update:modelValue", null);
    await input.vm.$emit("update:presetValue", "transport_alt1");

    expect(vm(wrapper).coverImagePreset).toBe("transport_alt1");
    expect(vm(wrapper).coverImage).toBeNull();
  });

  // Nothing attached, nothing to detach: the field says so by not asking, and
  // the key stays absent rather than removing a cover that was never there.
  it("asks to detach nothing when there is no saved cover", async () => {
    const wrapper = mountForm({ slug: "job-1", kind: "transport" });

    await field(wrapper).vm.$emit("update:presetValue", "transport");

    expect(vm(wrapper).coverImage).toBeUndefined();
  });

  /*
   * Removing the preset does not put the saved cover back, and must not: the
   * field stopped showing that cover the moment a preset replaced it, so
   * restoring it on submit would save something the control never displayed.
   * What the author is left looking at is an empty field, which is what they
   * get.
   */
  it("clears the preset without reviving the cover it replaced", async () => {
    const wrapper = mountForm(SAVED_COVER);
    const input = field(wrapper);

    await input.vm.$emit("update:modelValue", null);
    await input.vm.$emit("update:presetValue", "transport");

    expect(vm(wrapper).coverImage).toBeNull();

    await input.vm.$emit("update:presetValue", null);

    expect(vm(wrapper).coverImagePreset).toBeNull();
    expect(vm(wrapper).coverImage).toBeNull();
  });

  /*
   * The order that hid the problem the grid had: picking first wrote the same
   * `null` the author's own clear writes, so a clear afterwards changed nothing
   * visible and the form went on believing the `null` was its own.
   *
   * Nothing has to tell them apart here. Removing a preset restores nothing, so
   * there is only ever one `null` and it always means what the field is showing:
   * no picture.
   */
  it("keeps a clear the author made after picking a preset", async () => {
    const wrapper = mountForm(SAVED_COVER);
    const input = field(wrapper);

    await input.vm.$emit("update:presetValue", "transport");
    // What the field emits when its clear button is used.
    await input.vm.$emit("update:modelValue", null);
    await input.vm.$emit("update:presetValue", null);

    expect(vm(wrapper).coverImage).toBeNull();
  });

  /*
   * An upload made after a preset was picked outranks it, and removing the
   * preset must not take the upload with it. The field retires the preset by
   * itself when a file lands, so the two never reach the payload together --
   * this is the form keeping its side of that.
   */
  it("keeps an upload made after the preset was picked", async () => {
    const wrapper = mountForm(SAVED_COVER);
    const input = field(wrapper);

    await input.vm.$emit("update:presetValue", "transport");
    await input.vm.$emit("update:modelValue", "signed-id-1");
    await input.vm.$emit("update:presetValue", null);

    expect(vm(wrapper).coverImage).toBe("signed-id-1");
    expect(vm(wrapper).coverImagePreset).toBeNull();
  });

  // The reverse of what the grid did. It only ever offered the current kind's
  // art, so a preset naming another kind could only be a leftover; the picker
  // offers every kind and says so, which makes it a choice.
  it("keeps a preset the new kind does not file under itself", async () => {
    const wrapper = mountForm(SAVED_COVER);

    await field(wrapper).vm.$emit("update:presetValue", "transport_alt1");

    vm(wrapper).kind = "crafting";
    await wrapper.vm.$nextTick();

    expect(vm(wrapper).coverImagePreset).toBe("transport_alt1");
  });

  it("opens the picker on the kind the form is editing", async () => {
    const wrapper = mountForm(SAVED_COVER);

    expect(field(wrapper).props("presetCatalogue")).toBe("contracts");
    expect(field(wrapper).props("presetGroup")).toBe("transport");

    vm(wrapper).kind = "crafting";
    await wrapper.vm.$nextTick();

    expect(field(wrapper).props("presetGroup")).toBe("crafting");
  });
});

describe("ContractForm destination", () => {
  const DEPOT = {
    id: "depot",
    name: "Depot",
    slug: "depot",
    location: "Area 18",
    holder: "fleet",
  };
  const LOCKER = {
    id: "locker",
    name: "Locker",
    slug: "locker",
    location: null,
    holder: "user",
  };

  const destinationSelect = (wrapper: ReturnType<typeof mountForm>) =>
    wrapper
      .findAllComponents({ name: "BaseSelect" })
      .find((select) => select.attributes("name") === "destination")!;

  const submitted = async (wrapper: ReturnType<typeof mountForm>) => {
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    return ((createMutation.mock.calls.at(-1) as unknown[] | undefined) ??
      (updateMutation.mock.calls.at(-1) as unknown[]))[0] as {
      data: Record<string, unknown>;
    };
  };

  it("offers what the API says the reader may choose, own inventories marked", () => {
    destinations.value = [DEPOT, LOCKER];

    const options = destinationSelect(mountForm()).props("options") as {
      value: string;
      label: string;
    }[];

    expect(options).toEqual([
      { value: "fleet:depot", label: "Depot — Area 18" },
      {
        value: "user:locker",
        label: "labels.fleets.contracts.myHangarInventory(Locker)",
      },
    ]);
  });

  it("sends an own inventory as destinationInventoryId and clears the fleet one", async () => {
    createMutation.mockClear();
    destinations.value = [LOCKER];
    const wrapper = mountForm();

    await destinationSelect(wrapper).vm.$emit(
      "update:modelValue",
      "user:locker",
    );

    expect(
      wrapper.find("[data-test='contract-destination-hint']").exists(),
    ).toBe(true);

    const { data } = await submitted(wrapper);

    expect(data.destinationInventoryId).toBe("locker");
    expect(data.destinationFleetInventoryId).toBeNull();
  });

  it("sends a fleet inventory as destinationFleetInventoryId", async () => {
    createMutation.mockClear();
    destinations.value = [DEPOT];
    const wrapper = mountForm();

    await destinationSelect(wrapper).vm.$emit(
      "update:modelValue",
      "fleet:depot",
    );

    expect(
      wrapper.find("[data-test='contract-destination-hint']").exists(),
    ).toBe(false);

    const { data } = await submitted(wrapper);

    expect(data.destinationFleetInventoryId).toBe("depot");
    expect(data.destinationInventoryId).toBeNull();
  });

  // The API decides whose inventories are offered, so it has to know which
  // contract is being edited -- without it an editor would be offered their
  // own, which the model refuses on another author's contract.
  it("names the contract being edited when asking for destinations", () => {
    mountForm({ slug: "job-1", kind: "procurement" });

    expect(destinationParams.value?.value).toEqual({ contractSlug: "job-1" });

    mountForm();

    expect(destinationParams.value?.value).toEqual({});
  });

  // Somebody else editing still sees where it delivers, and keeps it by not
  // touching the field.
  it("keeps the author's inventory in the list for another editor", async () => {
    updateMutation.mockClear();
    destinations.value = [DEPOT];
    const wrapper = mountForm({
      slug: "job-1",
      kind: "procurement",
      destination: LOCKER,
      createdBy: { id: "author", username: "Ada" },
    });

    const options = destinationSelect(wrapper).props("options") as {
      value: string;
      label: string;
    }[];

    expect(options.at(-1)).toEqual({
      value: "user:locker",
      label: "labels.fleets.contracts.authorHangarInventory(Locker,Ada)",
    });

    const { data } = await submitted(wrapper);

    expect(data.destinationInventoryId).toBe("locker");
  });
});
