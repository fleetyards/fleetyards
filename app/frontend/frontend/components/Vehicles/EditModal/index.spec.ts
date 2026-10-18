import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import Component from "./index.vue";
import { flushPromises } from "@vue/test-utils";
import { VehicleEditTabsEnum } from "./types";
import { modalDirtyKey } from "@/shared/components/AppModal/dirty";

const mutateAsync = vi.fn().mockResolvedValue({});

const resolved = () => ({
  isPending: ref(false),
  isFetching: ref(false),
  isLoading: ref(false),
  isRefetching: ref(false),
  error: ref(undefined),
});

vi.mock("@/shared/components/base/FormFileInput/index.vue", () => ({
  default: { name: "FormFileInput", template: "<div />" },
}));
import { type Vehicle, BoughtViaEnum } from "@/services/fyApi";

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<typeof import("@/services/fyApi")>()),
  useVehicleBoughtViaFilters: () => ({
    data: ref([
      { label: "Pledge Store", value: "pledge_store", category: "boughtVia" },
      { label: "In-Game", value: "ingame", category: "boughtVia" },
    ]),
  }),
  useHangarGroups: () => ({ data: ref([]) }),
  useModelModules: () => ({
    data: ref({ items: [{ id: "m1", name: "Cargo Module", slug: "cargo" }] }),
    ...resolved(),
  }),
  useModelModulePackages: () => ({ data: ref({ items: [] }), ...resolved() }),
  useModelPaints: () => ({ data: ref([]), ...resolved() }),
  useVehiclePaints: () => ({
    data: ref([
      {
        owned: false,
        pledged: true,
        picture: false,
        paint: { id: "paint-pledged", name: "Pledged", media: {} },
      },
    ]),
    ...resolved(),
  }),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => true }),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({
    useUpdateMutation: () => ({ mutateAsync, isPending: ref(false) }),
  }),
}));

const vehicle = (ingameOnly: boolean): Vehicle =>
  ({
    id: "vehicle-1",
    flagship: false,
    public: true,
    nameVisible: true,
    name: "Old name",
    serial: "LEGACY SERIAL",
    boughtVia: BoughtViaEnum.PLEDGE_STORE,
    alternativeNames: [],
    modelModuleIds: [],
    modelUpgradeIds: [],
    modelPaintIds: [],
    hangarGroupIds: [],
    model: {
      id: "model-1",
      name: "ATLS IKTI",
      slug: "argo-atls-ikti",
      ingameOnly,
    },
  }) as unknown as Vehicle;

const boughtViaOptions = async (ingameOnly: boolean) => {
  const wrapper = await mountWithDefaults(Component, {
    props: { vehicle: vehicle(ingameOnly), wishlist: false },
  });

  return wrapper
    .findAllComponents({ name: "BaseSelect" })
    .find((select) => select.props("name") === "boughtVia")
    ?.props("options") as { value: string }[];
};

beforeEach(() => {
  mutateAsync.mockClear();
  Element.prototype.scrollTo = vi.fn();
});

describe("the way a ship was bought", () => {
  it("offers only in-game for a ship the pledge store never sells", async () => {
    expect(
      (await boughtViaOptions(true)).map((option) => option.value),
    ).toEqual(["ingame"]);
  });

  it("offers both for a pledge ship", async () => {
    expect(
      (await boughtViaOptions(false)).map((option) => option.value),
    ).toEqual(["pledge_store", "ingame"]);
  });
});

describe("VehicleEditModal", () => {
  it("opens the requested tab and saves only changed fields", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(false), tab: VehicleEditTabsEnum.NAMES },
    });

    expect(wrapper.find("#form-tab-panel-names").isVisible()).toBe(true);
    await wrapper.find('input[name="name"]').setValue("New name");
    await wrapper.find("form").trigger("submit");
    await vi.waitFor(() =>
      expect(mutateAsync).toHaveBeenCalledWith({
        id: "vehicle-1",
        data: { name: "New name" },
      }),
    );
  });

  it("records a module the ship owns", async () => {
    const v = vehicle(false);
    v.model.hasModules = true;
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: v, tab: VehicleEditTabsEnum.MODULES },
    });
    await flushPromises();

    await wrapper.get("[data-test='vehicle-addon-toggle']").trigger("click");
    await wrapper.find("form").trigger("submit");
    await vi.waitFor(() =>
      expect(mutateAsync).toHaveBeenCalledWith({
        id: "vehicle-1",
        data: { modelModuleIds: ["m1"] },
      }),
    );
  });

  it("saves a paint picked elsewhere", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(false), paintId: "paint-2" },
    });
    await wrapper.find("form").trigger("submit");
    await vi.waitFor(() =>
      expect(mutateAsync).toHaveBeenCalledWith({
        id: "vehicle-1",
        data: { modelPaintIds: ["paint-2"] },
      }),
    );
  });

  it("suggests the pledged paints once the paint tab is open", async () => {
    const painted = vehicle(false);
    painted.model.hasPaints = true;
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: painted, tab: VehicleEditTabsEnum.PAINT },
    });
    await flushPromises();
    await wrapper.find("form").trigger("submit");
    await vi.waitFor(() =>
      expect(mutateAsync).toHaveBeenCalledWith({
        id: "vehicle-1",
        data: { modelPaintIds: ["paint-pledged"] },
      }),
    );
  });

  it("does not ask before closing over the untouched paint suggestion", async () => {
    const sources: (() => boolean)[] = [];
    const painted = vehicle(false);
    painted.model.hasPaints = true;
    await mountWithDefaults(Component, {
      props: { vehicle: painted, tab: VehicleEditTabsEnum.PAINT },
      plugins: [
        {
          install: (app) =>
            app.provide(modalDirtyKey, (source) => {
              sources.push(source);
              return () => {};
            }),
        },
      ],
    });
    await flushPromises();

    expect(sources.map((source) => source())).toEqual([false]);
  });

  it("leaves the pledged paints unsaved while the paint tab stays closed", async () => {
    const painted = vehicle(false);
    painted.model.hasPaints = true;
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: painted },
    });
    await flushPromises();
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("does not save when nothing changed", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle: vehicle(false) },
    });
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(mutateAsync).not.toHaveBeenCalled();
  });

  it("offers a wishlist ship only its names and sale notifications", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        vehicle: vehicle(false),
        wishlist: true,
        tab: VehicleEditTabsEnum.VISIBILITY,
      },
    });

    expect(
      wrapper
        .findAllComponents({ name: "FormTab" })
        .filter((tab) => !tab.props("hidden"))
        .map((tab) => tab.props("id")),
    ).toEqual(["visibility", "names"]);
    expect(
      wrapper
        .findAllComponents({ name: "FormTab" })
        .find((tab) => tab.props("id") === "visibility")
        ?.props("label"),
    ).toBe("Notifications");
    expect(wrapper.find('input[name="saleNotify"]').exists()).toBe(true);
    expect(wrapper.find('input[name="public"]').exists()).toBe(false);
    expect(wrapper.find('input[name="nameVisible"]').exists()).toBe(false);
    expect(
      wrapper.find('input[name="logEntriesPublicByDefault"]').exists(),
    ).toBe(false);
    expect(wrapper.find('input[name="flagship"]').exists()).toBe(false);
  });

  it("opens a wishlist ship on its names when asked for a hangar tab", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        vehicle: vehicle(false),
        wishlist: true,
        tab: VehicleEditTabsEnum.IMAGE,
      },
    });

    expect(wrapper.find("#form-tab-panel-names").isVisible()).toBe(true);
  });
});
