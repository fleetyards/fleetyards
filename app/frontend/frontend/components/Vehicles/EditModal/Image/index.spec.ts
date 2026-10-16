import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises } from "@vue/test-utils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "../index.vue";
import { VehicleEditTabsEnum } from "../types";
import type { Image, ModelPaint, Vehicle } from "@/services/fyApi";

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
  useVehiclePaints: () => ({
    data: ref(
      [
        {
          id: "paint-1",
          name: "Rust Society",
          media: { storeImage: { url: "https://example.test/rust.jpg" } },
        },
        {
          id: "paint-2",
          name: "Stormbringer",
          media: { storeImage: { url: "https://example.test/storm.jpg" } },
        },
      ].map((paint) => ({
        owned: false,
        pledged: false,
        picture: false,
        paint: paint as ModelPaint,
      })),
    ),
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

const features = vi.hoisted(() => ({ enabled: true }));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => features.enabled }),
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
    modelModuleIds: [],
    modelUpgradeIds: [],
    modelPaintIds: [],
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
    features.enabled = true;
    updateVehicle.mockReset().mockResolvedValue({ id: "vehicle-1" });
  });

  it("picks a gallery picture and drops the upload so the pick shows", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");
    await wrapper
      .findAll('[data-test="vehicle-image-gallery-choice-toggle"]')[1]
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: "Image", pictureId: "image-2", image: null },
    });
  });

  it("offers the picture of every paint, owned or not", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ modelPaintIds: ["paint-2"] }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-paints"]')
      .trigger("click");

    expect(
      wrapper
        .findAll(
          '[data-test="vehicle-image-gallery-paint"] .addon-option__name',
        )
        .map((name) => name.text()),
    ).toEqual(["Rust Society", "Stormbringer"]);
    expect(
      wrapper
        .findAll('[data-test="vehicle-image-gallery-paint"]')
        .map((choice) => choice.find("[data-test='pill']").exists()),
    ).toEqual([false, true]);
    expect(
      wrapper.findAll('[data-test="vehicle-image-gallery-choice"]'),
    ).toHaveLength(0);
  });

  it("keeps the paints out of the model's gallery", async () => {
    const wrapper = await mount({ vehicle: vehicle() });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");

    expect(
      wrapper.findAll('[data-test="vehicle-image-gallery-choice"]'),
    ).toHaveLength(2);
    expect(
      wrapper.findAll('[data-test="vehicle-image-gallery-paint"]'),
    ).toHaveLength(0);
  });

  it("opens on the paints when the ship shows a paint's picture", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ pictureType: "ModelPaint", pictureId: "paint-2" }),
    });

    expect(
      wrapper.find('[data-test="vehicle-image-gallery-paints"]').exists(),
    ).toBe(true);
  });

  it("saves the pick of the open segment, not one made in the other", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ pictureType: "ModelPaint", pictureId: "paint-2" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");
    await wrapper
      .findAll('[data-test="vehicle-image-gallery-choice-toggle"]')[1]
      .trigger("click");
    await wrapper
      .find('[data-test="vehicle-image-source-paints"]')
      .trigger("click");

    expect(
      wrapper
        .findAll('[data-test="vehicle-image-gallery-paint-toggle"]')[1]
        .attributes("aria-pressed"),
    ).toBe("true");

    await submit(wrapper);

    expect(updateVehicle).not.toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ pictureType: "Image" }),
      }),
    );
  });

  it("saves nothing for a segment only opened", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ pictureType: "ModelPaint", pictureId: "paint-2" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");

    expect(
      wrapper
        .find('[data-test="vehicle-image-gallery-none-toggle"]')
        .attributes("aria-pressed"),
    ).toBe("false");

    await submit(wrapper);

    expect(updateVehicle).not.toHaveBeenCalledWith(
      expect.objectContaining({
        data: expect.objectContaining({ pictureType: null }),
      }),
    );
  });

  it("offers no paints segment without the vehicle overview", async () => {
    features.enabled = false;

    const wrapper = await mount({ vehicle: vehicle() });

    expect(
      wrapper.find('[data-test="vehicle-image-source-paints"]').exists(),
    ).toBe(false);
  });

  it("picks a paint's picture in place of a gallery picture", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        modelPaintIds: ["paint-2"],
        pictureType: "Image",
        pictureId: "image-1",
      }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-paints"]')
      .trigger("click");
    await wrapper
      .findAll('[data-test="vehicle-image-gallery-paint-toggle"]')[1]
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: "ModelPaint", pictureId: "paint-2", image: null },
    });
  });

  it("goes back to the standard picture from a paint's picture", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        modelPaintIds: ["paint-2"],
        pictureType: "ModelPaint",
        pictureId: "paint-2",
      }),
    });

    await wrapper
      .find('[data-test="vehicle-image-gallery-none-toggle"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: null, pictureId: null, image: null },
    });
  });

  it("goes back to the standard picture", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ pictureType: "Image", pictureId: "image-1" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-gallery-none-toggle"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: null, pictureId: null, image: null },
    });
  });

  it("saves nothing when the pick is unchanged", async () => {
    const wrapper = await mount({
      vehicle: vehicle({ pictureType: "Image", pictureId: "image-1" }),
    });

    await submit(wrapper);

    expect(updateVehicle).not.toHaveBeenCalled();
  });

  it("drops the upload even when the pick stays the same", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        image: { url: "https://example.test/own.jpg" } as Vehicle["image"],
        imageUploaded: true,
      }),
    });

    await wrapper
      .find('[data-test="vehicle-image-source-gallery"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: null, pictureId: null, image: null },
    });
  });

  it("removes an uploaded picture when the upload is cleared", async () => {
    const wrapper = await mount({
      vehicle: vehicle({
        image: { url: "https://example.test/own.jpg" } as Vehicle["image"],
        imageUploaded: true,
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
      vehicle: vehicle({ pictureType: "Image", pictureId: "image-gone" }),
    });

    await wrapper
      .find('[data-test="vehicle-image-gallery-none-toggle"]')
      .trigger("click");
    await submit(wrapper);

    expect(updateVehicle).toHaveBeenCalledWith({
      id: "vehicle-1",
      data: { pictureType: null, pictureId: null, image: null },
    });
  });
});
