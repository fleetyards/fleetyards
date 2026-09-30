import { afterEach, describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type VueWrapper } from "@vue/test-utils";
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
    ],
  });

const gun = (id: string, catalogued: boolean) =>
  ({
    id,
    name: `hardpoint_gun_${id}`,
    groupKey: "guns",
    source: HardpointSourceEnum.GAME_FILES,
    category: HardpointCategoryEnum.WEAPONS,
    maxSize: 3,
    component: {
      id: "c1",
      name: "Attrition-3",
      slug: "attrition-3",
      catalogued,
      category: "weapons",
      typeData: {},
    },
  }) as unknown as Hardpoint;

const wrappers: VueWrapper[] = [];

const mountStack = async (catalogued: boolean) => {
  const wrapper = await mountWithDefaults(Component, {
    props: { hardpoints: [gun("1", catalogued), gun("2", catalogued)] },
    plugins: [router()],
    attachTo: document.body,
  });
  wrappers.push(wrapper);

  return wrapper;
};

const tap = (target: Element) => {
  const trigger = target.closest("[data-test='popover-trigger']")!;
  const over = new Event("pointerover", { bubbles: true });
  Object.assign(over, { pointerType: "touch" });
  trigger.dispatchEvent(over);
  target.dispatchEvent(
    new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 }),
  );
};

// The summary row hides once the stack expands; the per-gun rows stay mounted
// inside Collapsed either way, so counting them says nothing.
const expanded = (wrapper: VueWrapper) =>
  (wrapper.find(".hardpoint-item").element as HTMLElement).style.display ===
  "none";

afterEach(() => {
  while (wrappers.length) wrappers.pop()?.unmount();
});

describe("HardpointBaseItem", () => {
  it.each([
    ["a catalogued", true],
    ["an uncatalogued", false],
  ])(
    "leaves the stack alone when %s component's card is tapped open and shut",
    async (_label, catalogued) => {
      const wrapper = await mountStack(catalogued);
      const name = wrapper.find("[data-test='popover-trigger']");
      const target = name.find("a").exists()
        ? name.find("a").element
        : name.element;

      tap(target);
      await nextTick();
      expect(document.querySelector("[data-test='popover']")).not.toBeNull();

      tap(target);
      await nextTick();
      expect(document.querySelector("[data-test='popover']")).toBeNull();

      expect(expanded(wrapper)).toBe(false);
    },
  );

  it("still toggles the stack from the rest of the row", async () => {
    const wrapper = await mountStack(true);

    await wrapper.find(".hardpoint-item").trigger("click");

    expect(expanded(wrapper)).toBe(true);
  });
});
