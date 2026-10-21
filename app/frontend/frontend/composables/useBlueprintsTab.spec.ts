import { describe, expect, it } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { defineComponent, h } from "vue";
import { mount } from "@vue/test-utils";
import { useBlueprintsTab } from "./useBlueprintsTab";

const setup = async (query: Record<string, string> = {}) => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [{ path: "/", name: "list", component: { template: "<div />" } }],
  });
  await router.push({ name: "list", query });
  await router.isReady();

  let tab!: ReturnType<typeof useBlueprintsTab>["activeTab"];

  mount(
    defineComponent({
      setup() {
        tab = useBlueprintsTab().activeTab;

        return () => h("div");
      },
    }),
    { global: { plugins: [router] } },
  );

  return { router, tab };
};

describe("useBlueprintsTab", () => {
  it("opens on the owned list", async () => {
    const { tab } = await setup();

    expect(tab.value).toBe("owned");
  });

  it("reads the wanted list from the query", async () => {
    const { tab } = await setup({ tab: "wanted" });

    expect(tab.value).toBe("wanted");
  });

  // Page three of one list is not page three of the other.
  it("drops the page when switching", async () => {
    const { router, tab } = await setup({ page: "3", nameCont: "cannon" });

    tab.value = "wanted";
    await router.isReady();
    await new Promise((resolve) => setTimeout(resolve));

    expect(router.currentRoute.value.query).toEqual({
      nameCont: "cannon",
      tab: "wanted",
    });
  });
});
