import { afterEach, describe, expect, it, vi } from "vitest";
import { createRouter, createWebHashHistory } from "vue-router";
import { type VueWrapper } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import ComponentRow from "@/frontend/components/Components/Row/index.vue";
import EquipmentRow from "@/frontend/components/Equipment/Row/index.vue";
import CommodityRow from "@/frontend/components/Commodities/Row/index.vue";

const routerOnList = async () => {
  const router = createRouter({
    history: createWebHashHistory(),
    routes: [
      { path: "/list", name: "list", component: { template: "<div />" } },
      ...["component", "equipment-item", "commodity"].map((name) => ({
        path: `/${name}/:slug`,
        name,
        component: { template: "<div />" },
      })),
    ],
  });

  await router.push({ name: "list" });
  await router.isReady();

  return router;
};

const record = {
  id: "1",
  name: "Glacier",
  slug: "glacier",
  category: "cooler",
  typeData: { coolingRate: 50 },
  containerSizes: [],
  consumable: false,
  counted: false,
  retired: false,
};

const wrappers: VueWrapper[] = [];

afterEach(() => {
  while (wrappers.length) wrappers.pop()?.unmount();
  vi.restoreAllMocks();
});

// The row's name is the row's link, so that link is the one focus stop and the
// one the keyboard reaches the card from.
describe.each([
  ["component", ComponentRow, { component: record }],
  ["equipment", EquipmentRow, { equipment: record }],
  ["commodity", CommodityRow, { commodity: record }],
])("the %s catalogue row", (_name, Row, props) => {
  const mountRow = async () => {
    const wrapper = await mountWithDefaults(Row as never, {
      props: props as never,
      plugins: [await routerOnList()],
      attachTo: document.body,
    });
    wrappers.push(wrapper);

    return wrapper;
  };

  it("opens the name's card from keyboard focus on the row's link", async () => {
    const wrapper = await mountRow();
    const link = wrapper.find("a.row-list-item__name");

    vi.spyOn(HTMLElement.prototype, "matches").mockImplementation(
      (selector: string) => selector === ":focus-visible",
    );

    (link.element as HTMLElement).focus();
    await nextTick();

    const panel = document.querySelector("[data-test='popover']");
    expect(panel).not.toBeNull();
    expect(link.attributes("aria-describedby")).toBe(panel!.id);
  });

  it("keeps a single focus stop and no link inside the link", async () => {
    const wrapper = await mountRow();
    const link = wrapper.find("a.row-list-item__name");

    expect(link.findAll("a")).toHaveLength(0);
    expect(link.find("[tabindex]").exists()).toBe(false);
  });
});
