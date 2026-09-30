import { afterEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

const componentEnabled = vi.fn();
const equipmentEnabled = vi.fn();

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useComponent: (
    _slug: unknown,
    options: { query: { enabled: { value: boolean } } },
  ) => {
    componentEnabled.mockImplementation(() => options.query.enabled.value);

    return { data: ref(undefined), isPending: ref(true) };
  },
  useEquipmentItem: (
    _slug: unknown,
    options: { query: { enabled: { value: boolean } } },
  ) => {
    equipmentEnabled.mockImplementation(() => options.query.enabled.value);

    return { data: ref(undefined), isPending: ref(true) };
  },
}));

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
        path: "/equipment/:slug",
        name: "equipment-item",
        component: { template: "<div />" },
      },
      {
        path: "/commodities/:slug",
        name: "commodity",
        component: { template: "<div />" },
      },
    ],
  });

const wrappers: VueWrapper[] = [];

const mount = async (item: Record<string, unknown>) => {
  const wrapper = await mountWithDefaults(Component, {
    props: { item: item as InstanceType<typeof Component>["$props"]["item"] },
    plugins: [router()],
    attachTo: document.body,
  });
  wrappers.push(wrapper);

  return wrapper;
};

const tapOpen = async (wrapper: VueWrapper) => {
  const trigger = wrapper.find("[data-test='stats-popover-trigger']");
  const over = new Event("pointerover", { bubbles: true });
  Object.assign(over, { pointerType: "touch" });
  trigger.element.dispatchEvent(over);
  trigger.element.dispatchEvent(
    new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 }),
  );
  await nextTick();
};

afterEach(() => {
  while (wrappers.length) wrappers.pop()?.unmount();
});

describe("CatalogueItemLink", () => {
  it("fetches a component's card only once it is opened", async () => {
    const wrapper = await mount({
      type: "Component",
      slug: "glacier",
      name: "Glacier",
    });

    expect(componentEnabled()).toBe(false);

    await tapOpen(wrapper);

    expect(componentEnabled()).toBe(true);
    expect(equipmentEnabled()).toBe(false);
    expect(
      document.querySelector("[data-test='stats-popover'] .stats-card"),
    ).not.toBeNull();
  });

  it("fetches an equipment item's card the same way", async () => {
    const wrapper = await mount({
      type: "Equipment",
      slug: "morozov-sh-core",
      name: "Morozov-SH Core",
    });

    await tapOpen(wrapper);

    expect(equipmentEnabled()).toBe(true);
    expect(componentEnabled()).toBe(false);
  });

  it("is a plain link for a record with no stats card", async () => {
    const wrapper = await mount({
      type: "Commodity",
      slug: "agricium",
      name: "Agricium",
    });

    expect(wrapper.find("[data-test='stats-popover-trigger']").exists()).toBe(
      false,
    );
    expect(wrapper.find("a").attributes("href")).toBe("#/commodities/agricium");
  });

  it("is plain text for a record the catalogue does not list", async () => {
    const wrapper = await mount({
      type: "Equipment",
      slug: "hidden-variant",
      name: "Hidden Variant",
      listed: false,
    });

    expect(wrapper.find("a").exists()).toBe(false);
    expect(wrapper.text()).toBe("Hidden Variant");
  });
});
