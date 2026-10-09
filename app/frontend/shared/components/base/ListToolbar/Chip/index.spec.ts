import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { flushPromises } from "@vue/test-utils";
import Component from "./index.vue";

type ChipWrapper = {
  find: (selector: string) => {
    element: HTMLElement;
    trigger: (event: string) => Promise<void>;
  };
};

const mountChip = async (
  query: Record<string, string> = {},
  fallback = "name asc",
) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "list", component: { render: () => null } }],
  });

  await router.push({ name: "list", query });

  const wrapper = (await mountWithDefaults(
    Component as never,
    {
      props: { label: "Name", field: "name", fallback },
      plugins: [router],
    } as never,
  )) as unknown as ChipWrapper;

  const rightClick = async () => {
    const event = new MouseEvent("contextmenu", { cancelable: true });

    wrapper.find(".base-list-toolbar-chip").element.dispatchEvent(event);
    await flushPromises();

    return event;
  };

  const click = async () => {
    await wrapper.find(".base-list-toolbar-chip").trigger("click");
    await flushPromises();

    return router.currentRoute.value.query;
  };

  return { router, rightClick, click };
};

describe("BaseListToolbarChip", () => {
  it("resets its sort on a right click", async () => {
    const { router, rightClick } = await mountChip({ s: "name desc", q: "x" });

    const event = await rightClick();

    expect(event.defaultPrevented).toBe(true);
    expect(router.currentRoute.value.query).toEqual({ q: "x" });
  });

  it("keeps the browser's menu on another field's sort", async () => {
    const { router, rightClick } = await mountChip({ s: "price asc" });

    const event = await rightClick();

    expect(event.defaultPrevented).toBe(false);
    expect(router.currentRoute.value.query).toEqual({ s: "price asc" });
  });

  it("keeps the browser's menu while only the default is lit", async () => {
    const { router, rightClick } = await mountChip();

    const event = await rightClick();

    expect(event.defaultPrevented).toBe(false);
    expect(router.currentRoute.value.query).toEqual({});
  });

  it("toggles a descending default between both directions", async () => {
    const { click } = await mountChip({}, "name desc");

    expect(await click()).toEqual({ s: "name asc" });
    expect(await click()).toEqual({});
  });

  it("toggles an ascending default between both directions", async () => {
    const { click } = await mountChip({}, "name asc");

    expect(await click()).toEqual({ s: "name desc" });
    expect(await click()).toEqual({});
  });

  it("cycles another field through none, ascending and descending", async () => {
    const { click } = await mountChip({}, "price asc");

    expect(await click()).toEqual({ s: "name asc" });
    expect(await click()).toEqual({ s: "name desc" });
    expect(await click()).toEqual({});
  });

  it("goes back to the first page when the sort changes", async () => {
    const { click } = await mountChip({ page: "4", q: "x" });

    expect(await click()).toEqual({ s: "name desc", q: "x" });
  });
});
