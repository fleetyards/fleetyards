import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { flushPromises } from "@vue/test-utils";
import Component from "./index.vue";

type ChipWrapper = {
  find: (selector: string) => { element: HTMLElement };
};

const mountChip = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "list", component: { render: () => null } }],
  });

  await router.push({ name: "list", query });

  const wrapper = (await mountWithDefaults(
    Component as never,
    {
      props: { label: "Name", field: "name", fallback: "name asc" },
      plugins: [router],
    } as never,
  )) as unknown as ChipWrapper;

  const rightClick = async () => {
    const event = new MouseEvent("contextmenu", { cancelable: true });

    wrapper.find(".base-list-toolbar-chip").element.dispatchEvent(event);
    await flushPromises();

    return event;
  };

  return { router, rightClick };
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
});
