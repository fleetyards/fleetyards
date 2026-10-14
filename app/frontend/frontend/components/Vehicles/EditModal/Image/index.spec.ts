import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "../index.vue";
import { VehicleEditTabsEnum } from "../types";
import type { Image, Vehicle } from "@/services/fyApi";

const updateVehicle = vi.fn();

const gallery = vi.hoisted(() => ({
  items: [] as { id: string; url: string }[],
}));

const GALLERY = [
  { id: "image-1", url: "https://example.test/1.jpg" },
  { id: "image-2", url: "https://example.test/2.jpg" },
];

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useHangarGroups: () => ({ data: ref([]) }),
  useVehicleBoughtViaFilters: () => ({ data: ref([]) }),
  useModelImages: () => ({
    data: ref({
      items: gallery.items as Image[],
      meta: {
        pagination: {
          totalCount: gallery.items.length,
          currentPage: 1,
          totalPages: 1,
          perPage: 48,
        },
      },
    }),
    isLoading: ref(false),
  }),
  useUpdateVehicle: () => ({
    mutateAsync: updateVehicle,
    isPending: ref(false),
  }),
}));

// The upload field pulls three.js in through its preset picker, which the test
// environment cannot load; the stub only reports a clear the way the real one does.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: {
    name: "FormFileInput",
    emits: ["update:modelValue"],
    template:
      '<button type="button" data-test="file-input-clear" @click="$emit(\'update:modelValue\', null)" />',
  },
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync: vi.fn(), isPending: ref(false) }),
    invalidateVehiclePage: vi.fn(),
    invalidateHangarQueries: vi.fn(),
  }),
}));

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    alternativeNames: [],
    hangarGroupIds: [],
    model: { name: "Ironclad", slug: "ironclad", media: {} },
    ...overrides,
  }) as Vehicle;

const mount = (props: { vehicle: Vehicle }) =>
  mountWithDefaults(Component, {
    props: { ...props, tab: VehicleEditTabsEnum.IMAGE },
  });

const submit = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

describe("VehicleEditModal image tab", () => {
  beforeEach(() => {
    gallery.items = GALLERY;
    updateVehicle.mockReset().mockResolvedValue({ id: "vehicle-1" });
  });

  it("picks a gallery picture and drops the upload so the pick shows", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");
    await wrapper
      .findAll('[data-test="vehicle-image-gallery-choice"]')[1]
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { modelImageId: "image-2", image: null },
    });
  });

  it("goes back to the standard picture", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ modelImageId: "image-1" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-gallery-none"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { modelImageId: null, image: null },
    });
  });

  it("saves nothing when the pick is unchanged", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ modelImageId: "image-1" }),
    });

    await submit(wrapper);

    expect(updateVehicle).not.toHaveBeenCalled();
  });

  it("drops the upload even when the pick stays the same", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        image: { url: "https://example.test/own.jpg" } as Vehicle["image"],
      }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { modelImageId: null, image: null },
    });
  });

  it("removes an uploaded picture when the upload is cleared", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        image: { url: "https://example.test/own.jpg" } as Vehicle["image"],
      }),
    });

    await wrapper.find('[data-test="file-input-clear"]').trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { image: null },
    });
  });

  it("can still go back to the standard picture with an empty gallery", async () => {
    gallery.items = [];

    const wrapper = await mount({
      vehicle: vehicle({ modelImageId: "image-gone" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-gallery-none"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { modelImageId: null, image: null },
    });
  });
});
