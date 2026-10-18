import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it, vi } from "vitest";
import { ModelProductionStatusEnum, type Vehicle } from "@/services/fyApi";
import Component from "./loadouts.vue";

const { updateLoadout, loadouts, mutation, openLoadoutModal, editor } =
  vi.hoisted(() => ({
    editor: { enabled: true },
    openLoadoutModal: vi.fn(),
    mutation:
      (mutateAsync = vi.fn(() => Promise.resolve())) =>
      () => ({
        mutateAsync,
        isPending: ref(false),
      }),
    updateLoadout: vi.fn(() => Promise.resolve()),
    loadouts: [
      {
        id: "l1",
        name: "Hauler",
        kind: "fleetyards",
        active: true,
        public: false,
        items: [],
        createdAt: "2026-10-01T00:00:00Z",
        updatedAt: "2026-10-01T00:00:00Z",
      },
      {
        id: "l2",
        name: "Brawler",
        kind: "fleetyards",
        active: false,
        public: true,
        items: [],
        createdAt: "2026-10-01T00:00:00Z",
        updatedAt: "2026-10-01T00:00:00Z",
      },
      {
        id: "l3",
        name: "Erkul build",
        kind: "link",
        url: "https://www.erkul.games/loadout/abc",
        urlSource: "erkul",
        active: false,
        public: false,
        items: [],
        createdAt: "2026-10-01T00:00:00Z",
        updatedAt: "2026-10-01T00:00:00Z",
      },
    ],
  }));

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useVehicleLoadouts: () => ({ data: ref(loadouts), isLoading: ref(false) }),
  useCreateVehicleLoadout: mutation(),
  useUpdateVehicleLoadout: mutation(updateLoadout),
  useDestroyVehicleLoadout: mutation(),
  useActivateVehicleLoadout: mutation(),
}));

// The desktop row, whose actions sit in the row rather than a menu.
vi.mock("@/shared/composables/useMobile", () => ({
  useMobile: () => ref(false),
}));

vi.mock("@/frontend/composables/useVehicleModals", () => ({
  useVehicleModals: () => ({ openLoadoutModal, openLoadoutView: vi.fn() }),
}));

vi.mock("@/frontend/composables/useFeatures", () => ({
  useFeatures: () => ({ isFeatureEnabled: () => editor.enabled }),
}));

vi.mock("@/frontend/composables/useVehicleMutations", () => ({
  useVehicleMutations: () => ({ invalidateVehiclePage: vi.fn() }),
}));

const vehicle = {
  id: "v1",
  model: {
    slug: "scorpius",
    productionStatus: ModelProductionStatusEnum.FLIGHT_READY,
  },
} as unknown as Vehicle;

describe("HangarVehicleLoadoutsPage", () => {
  it("marks the public loadouts and leads from a name to its page", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='loadout-public-l1']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='loadout-public-l2']").exists()).toBe(true);
    expect(wrapper.find("[data-test='loadout-visibility-l1']").exists()).toBe(
      false,
    );
    expect(
      wrapper.get("[data-test='loadout-page-l2']").attributes("href"),
    ).toContain("/loadouts/l2/");

    const link = wrapper.get("[data-test='loadout-link-l3']");
    expect(link.attributes("href")).toBe("https://www.erkul.games/loadout/abc");
    expect(link.attributes("target")).toBe("_blank");

    expect(wrapper.get("[data-test='loadout-kind-l2']").text()).toBe(
      "Fleetyards",
    );
    expect(wrapper.get("[data-test='loadout-kind-l3']").text()).toBe("Erkul");
  });

  it("starts a new loadout on a ship without modules, which still has parts to fit", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(
      wrapper
        .get("[data-test='loadouts-new-fleetyards']")
        .attributes("disabled"),
    ).toBeUndefined();
  });

  it("starts every new loadout in the editor, a linked build included", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='loadouts-add']").exists()).toBe(false);
    expect(wrapper.find("[data-test='loadouts-new-fleetyards']").exists()).toBe(
      true,
    );
  });

  it("edits every loadout in the editor rather than in the row", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='start-edit']").exists()).toBe(false);

    await wrapper.get("[data-test='loadout-edit-l2']").trigger("click");

    expect(openLoadoutModal).toHaveBeenCalledWith(
      vehicle,
      expect.objectContaining({ editable: true, loadoutId: "l2" }),
    );
  });

  it("gives every row the same buttons, a linked build viewed on its site", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='loadout-view-fitting-l2']").exists()).toBe(
      true,
    );
    expect(
      wrapper.get("[data-test='loadout-view-link-l3']").attributes("href"),
    ).toBe("https://www.erkul.games/loadout/abc");

    const active = wrapper.get("[data-test='loadout-activate-l1']");
    expect(active.attributes("disabled")).toBeDefined();
    expect(active.classes()).toContain("loadouts-page__activate--active");
    expect(
      wrapper.get("[data-test='loadout-activate-l2']").attributes("disabled"),
    ).toBeUndefined();
  });

  it("switches visibility on the row where the editor is not available", async () => {
    editor.enabled = false;
    updateLoadout.mockClear();

    const wrapper = await mountWithDefaults(Component, {
      props: { vehicle },
    });

    expect(wrapper.find("[data-test='loadout-edit-l1']").exists()).toBe(false);
    await wrapper.get("[data-test='loadout-visibility-l1']").trigger("click");

    expect(updateLoadout).toHaveBeenCalledWith({
      vehicleId: "v1",
      id: "l1",
      data: { public: true },
    });

    editor.enabled = true;
  });
});
