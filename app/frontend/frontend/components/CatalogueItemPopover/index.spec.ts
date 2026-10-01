import { afterEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";

type QueryOptions = { query: { enabled: { value: boolean } } };

// Hoisted with the mock below, which runs before the rest of this file. Each
// query reports the v5 states: pending (disabled, or in flight) until `settle`
// answers it, then data or an error, and no longer pending.
const { enabled, query, settle } = vi.hoisted(() => {
  const enabled: Record<string, () => boolean> = {};
  const states: Record<
    string,
    { data: Ref<unknown>; isPending: Ref<boolean> }
  > = {};

  const query = (key: string) => (_slug: unknown, options: QueryOptions) => {
    enabled[key] = () => options.query.enabled.value;
    states[key] = { data: ref(undefined), isPending: ref(true) };

    return states[key];
  };

  const settle = (key: string, data?: unknown) => {
    states[key].data.value = data;
    states[key].isPending.value = false;
  };

  return { enabled, query, settle };
});

vi.mock("@/services/fyApi", async (importOriginal) => ({
  ...(await importOriginal<Record<string, unknown>>()),
  useComponent: query("component"),
  useEquipmentItem: query("equipment"),
  useCommodity: query("commodity"),
}));

import Component from "./index.vue";

const router = () =>
  createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/", name: "home", component: { template: "<div />" } },
      ...["component", "equipment-item", "commodity"].map((name) => ({
        path: `/${name}/:slug`,
        name,
        component: { template: "<div />" },
      })),
    ],
  });

const wrappers: VueWrapper[] = [];

type Props = InstanceType<typeof Component>["$props"];

const mount = async (props: Props) => {
  const wrapper = await mountWithDefaults(Component, {
    props,
    plugins: [router()],
    attachTo: document.body,
  });
  wrappers.push(wrapper);

  return wrapper;
};

const tapOpen = async (wrapper: VueWrapper) => {
  const trigger = wrapper.find("[data-test='popover-trigger']");
  const over = new Event("pointerover", { bubbles: true });
  Object.assign(over, { pointerType: "touch" });
  trigger.element.dispatchEvent(over);
  trigger.element.dispatchEvent(
    new MouseEvent("click", { bubbles: true, cancelable: true, detail: 1 }),
  );
  await nextTick();
};

const card = () =>
  document.querySelector("[data-test='popover'] [data-test='stats-card']");

afterEach(() => {
  while (wrappers.length) wrappers.pop()?.unmount();
});

describe("CatalogueItemPopover", () => {
  it.each([
    ["Component", "component"],
    ["Equipment", "equipment"],
    ["Commodity", "commodity"],
  ])("fetches a %s reference's card only once it opens", async (type, key) => {
    const wrapper = await mount({
      item: { type, slug: "glacier", name: "Glacier" },
    });

    expect(enabled[key]()).toBe(false);

    await tapOpen(wrapper);

    expect(enabled[key]()).toBe(true);
    Object.entries(enabled)
      .filter(([other]) => other !== key)
      .forEach(([, isEnabled]) => expect(isEnabled()).toBe(false));
    expect(card()).not.toBeNull();
  });

  it("fetches nothing when handed the record itself", async () => {
    const wrapper = await mount({
      item: { type: "Component", slug: "glacier", name: "Glacier" },
      record: {
        id: "1",
        name: "Glacier",
        slug: "glacier",
        category: "cooler",
        typeData: { coolingRate: 50 },
      } as unknown as Props["record"],
    });

    await tapOpen(wrapper);

    expect(enabled.component()).toBe(false);
    expect(card()?.textContent).toContain("Glacier");
  });

  it("opens a card for a record the catalogue does not list, without a link", async () => {
    const wrapper = await mount({
      item: { type: "Component", slug: "door", name: "Door", listed: false },
      record: {
        id: "2",
        name: "Door",
        slug: "door",
      } as unknown as Props["record"],
    });

    expect(wrapper.find("a").exists()).toBe(false);

    await tapOpen(wrapper);

    expect(card()).not.toBeNull();
    expect(document.querySelector("[data-test='stats-card-link']")).toBeNull();
  });

  it("adds no link or focus stop inside a link it already sits in", async () => {
    const wrapper = await mount({
      item: { type: "Commodity", slug: "agricium", name: "Agricium" },
      link: false,
      focusable: false,
    });
    await nextTick();

    expect(wrapper.find("a").exists()).toBe(false);
    expect(
      wrapper.find("[data-test='popover-trigger']").attributes("tabindex"),
    ).toBeUndefined();
  });

  it("is plain text for a reference with neither a record nor a page", async () => {
    const wrapper = await mount({
      item: {
        type: "Equipment",
        slug: "hidden-variant",
        name: "Hidden Variant",
        listed: false,
      },
    });

    expect(wrapper.find("[data-test='popover-trigger']").exists()).toBe(false);
    expect(wrapper.text()).toBe("Hidden Variant");
  });

  it("names an icon-only trigger for assistive tech", async () => {
    const wrapper = await mount({
      item: { type: "Commodity", slug: "agricium" },
      linkLabel: "Open in catalogue",
    });

    expect(wrapper.find("a").attributes("aria-label")).toBe(
      "Open in catalogue",
    );
  });

  it("shows its skeleton while the lookup is in flight, and says so when it fails", async () => {
    const wrapper = await mount({
      item: { type: "Component", slug: "gone", name: "Gone" },
    });

    await tapOpen(wrapper);

    const skeleton = "[data-test='stats-card-skeleton']";
    expect(document.querySelector(skeleton)).not.toBeNull();
    expect(
      document.querySelector("[data-test='stats-card-unavailable']"),
    ).toBeNull();

    settle("component");
    await nextTick();

    expect(document.querySelector(skeleton)).toBeNull();
    expect(
      document.querySelector("[data-test='stats-card-unavailable']"),
    ).not.toBeNull();
    expect(card()?.textContent).toContain("Gone");
  });
});
