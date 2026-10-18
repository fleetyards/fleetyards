import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import {
  HardpointCategoryEnum,
  HardpointSourceEnum,
  type Hardpoint,
} from "@/services/fyApi";
import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      {
        path: "/components/:slug",
        name: "component",
        component: { template: "<div />" },
      },
      {
        path: "/ships/:slug/cargo-grids",
        name: "model-cargo-grids",
        component: { template: "<div />" },
      },
    ],
  });

const part = (id: string, name: string, hardpoints: Hardpoint[] = []) =>
  ({
    id,
    name,
    groupKey: name,
    source: HardpointSourceEnum.GAME_FILES,
    category: HardpointCategoryEnum.TURRET,
    maxSize: 3,
    component: { id: `c-${id}`, name: `Part ${id}`, typeData: {} },
    hardpoints,
  }) as unknown as Hardpoint;

const mount = (hardpoints: Hardpoint[]) =>
  mountWithDefaults(Component, {
    props: { hardpoints, category: HardpointCategoryEnum.TURRET },
    plugins: [router()],
  });

// Each part's contents sit in a Collapsed, hidden with `display: none`.
const shown = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper
    .findAll(".hardpoint-item__loadout")
    .map((list) => list.element.parentElement!.style.display !== "none");

describe("HardpointCategory", () => {
  it("folds what sits inside every part at once, and opens it again", async () => {
    const wrapper = await mount([
      part("1", "hardpoint_turret_left", [part("1a", "hardpoint_gun")]),
      part("2", "hardpoint_turret_right", [part("2a", "hardpoint_gun")]),
    ]);

    expect(shown(wrapper)).toEqual([true, true]);

    await wrapper.get("[data-test='hardpoint-category-fold']").trigger("click");
    expect(shown(wrapper)).toEqual([false, false]);

    await wrapper.get("[data-test='hardpoint-category-fold']").trigger("click");
    expect(shown(wrapper)).toEqual([true, true]);
  });

  it("offers no fold where no part holds anything", async () => {
    const wrapper = await mount([part("1", "hardpoint_turret")]);

    expect(wrapper.find("[data-test='hardpoint-category-fold']").exists()).toBe(
      false,
    );
  });
});
