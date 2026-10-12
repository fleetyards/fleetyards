import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
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
// environment cannot load; these cases are about the gallery.
vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: { name: "FormFileInput", template: "<div />" },
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    invalidateVehiclePage: vi.fn(),
    invalidateHangarQueries: vi.fn(),
  }),
}));

const vehicle = (overrides: Partial<Vehicle> = {}): Vehicle =>
  ({
    id: "vehicle-1",
    model: { name: "Ironclad", slug: "ironclad", media: {} },
    ...overrides,
  }) as Vehicle;

const mount = (props: { vehicle: Vehicle }) =>
  mountWithDefaults(Component, { props });

const submit = async (wrapper: Awaited<ReturnType<typeof mount>>) => {
  await wrapper.find("form").trigger("submit");
  await flushPromises();
};

describe("VehicleImageModal", () => {
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
});
