import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import type { Model, StorageContainer } from "@/services/fyApi";
import Component from "./index.vue";

const model = (storageContainers: StorageContainer[]) =>
  ({ id: "model-1", storageContainers }) as unknown as Model;

const pod = (name: string): StorageContainer =>
  ({
    name,
    componentName: "MISC Ore Pod",
    capacity: 8,
    kind: "ore",
  }) as StorageContainer;

describe("ModelStorageContainers", () => {
  it("shows ore pods and salvage storage as a card each", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        model: model([
          pod("hardpoint_mining_pod_1"),
          pod("hardpoint_mining_pod_2"),
          {
            name: "hardpoint_internal_storage",
            componentName: null,
            capacity: 13,
            kind: "salvage",
          } as StorageContainer,
        ]),
      },
    });

    const ore = wrapper.get("[data-test='storage-containers-ore']");
    expect(ore.text()).toContain("Ore pods");
    expect(ore.text()).toContain("16");
    expect(ore.text()).toContain("MISC Ore Pod");

    const salvage = wrapper.get("[data-test='storage-containers-salvage']");
    expect(salvage.text()).toContain("Salvage storage");
    expect(salvage.text()).toContain("13");
  });

  it("shows nothing for a ship without any", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { model: model([]) },
    });

    expect(wrapper.find("[data-test^='storage-containers']").exists()).toBe(
      false,
    );
  });
});
