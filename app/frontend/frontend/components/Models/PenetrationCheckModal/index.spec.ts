import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { beforeEach, describe, expect, it, vi } from "vitest";
import { ref } from "vue";
import {
  HardpointCategoryEnum,
  type Hardpoint,
  type ModelDefense,
} from "@/services/fyApi";
import Component from "./index.vue";

const defenses = ref<ModelDefense[] | undefined>();
const isError = ref(false);

vi.mock("@/services/fyApi", async () => {
  const actual =
    await vi.importActual<Record<string, unknown>>("@/services/fyApi");

  return {
    ...actual,
    useModelDefenses: () => ({
      data: defenses,
      isLoading: ref(false),
      isError,
    }),
  };
});

const ship = (
  id: string,
  size: string,
  deflectionPhysical: number,
): ModelDefense => ({
  id,
  name: id,
  slug: id,
  size,
  armor: { health: 1000, deflectionPhysical },
  shields: [],
});

const gun = (id: string, physical: number): Hardpoint =>
  ({
    id: `slot-${id}`,
    name: "hardpoint_weapon",
    category: HardpointCategoryEnum.WEAPONS,
    component: {
      id,
      name: id,
      slug: id,
      size: "3",
      typeData: { damagePerShot: { physical } },
    },
    hardpoints: [],
  }) as unknown as Hardpoint;

const mountModal = (hardpoints: Hardpoint[]) =>
  mountWithDefaults(Component, { props: { modelName: "Arrow", hardpoints } });

describe("ModelPenetrationCheckModal", () => {
  beforeEach(() => {
    isError.value = false;
    defenses.value = [ship("light", "small", 10), ship("heavy", "large", 150)];
  });

  it("tallies the ships the loadout pierces and deflects", async () => {
    const wrapper = await mountModal([gun("cannon", 100)]);

    expect(wrapper.findAll('[data-test="penetration-row"]')).toHaveLength(2);
    expect(wrapper.find('[data-test="penetration-tally"]').text()).toMatch(
      /1\D+1/,
    );
  });

  it("narrows the list to one ship size", async () => {
    const wrapper = await mountModal([gun("cannon", 100)]);

    const large = wrapper
      .findAll('[data-test="penetration-size"]')
      .find((button) => button.text() === "Large")!;
    await large.trigger("click");

    const rows = wrapper.findAll('[data-test="penetration-row"]');
    expect(rows).toHaveLength(1);
    expect(rows[0].text()).toContain("heavy");
  });

  it("drops a deselected gun from the comparison", async () => {
    const wrapper = await mountModal([gun("cannon", 200), gun("pea", 5)]);

    expect(wrapper.find(".tally__pierce").text()).toBe("2");

    const cannon = wrapper
      .findAll('[data-test="penetration-weapon"]')
      .find((button) => button.text().includes("cannon"))!;
    await cannon.trigger("click");

    expect(wrapper.find(".tally__pierce").text()).toBe("0");
  });

  it("says so when the defenses cannot be loaded", async () => {
    defenses.value = undefined;
    isError.value = true;

    const wrapper = await mountModal([gun("cannon", 100)]);

    expect(wrapper.find('[data-test="penetration-error"]').exists()).toBe(true);
    expect(wrapper.findAll('[data-test="penetration-row"]')).toHaveLength(0);
  });
});
