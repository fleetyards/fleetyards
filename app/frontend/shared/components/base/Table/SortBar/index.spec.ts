import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { h } from "vue";
import Component from "./index.vue";

type BarWrapper = {
  find: (selector: string) => {
    exists: () => boolean;
    find: (selector: string) => { setValue: (value: boolean) => Promise<void> };
  };
  findComponent: (query: { name: string }) => {
    props: (name: string) => unknown;
    vm: { $emit: (event: string, ...args: unknown[]) => void };
  };
  emitted: (name: string) => unknown[][] | undefined;
  text: () => string;
};

const columns = [{ name: "name", label: "Name", sortable: true }];

const mountBar = async (props: Record<string, unknown> = {}) =>
  (await mountWithDefaults(
    Component as never,
    {
      props: { columns, ...props },
      slots: { "selected-actions": () => h("span", "bulk actions") },
    } as never,
  )) as unknown as BarWrapper;

const selectAll = (wrapper: BarWrapper) =>
  wrapper.findComponent({ name: "FormCheckbox" });

describe("BaseTableSortBar", () => {
  it("offers no selection to a list whose rows cannot be picked", async () => {
    const wrapper = await mountBar();

    expect(wrapper.find('[data-test="sort-bar-select-all"]').exists()).toBe(
      false,
    );
    expect(wrapper.text()).not.toContain("bulk actions");
  });

  it("picks every row on screen", async () => {
    const wrapper = await mountBar({
      selectable: true,
      recordIds: ["a", "b"],
      selected: ["z"],
    });

    selectAll(wrapper).vm.$emit("update:modelValue", true);

    expect(wrapper.emitted("update:selected")?.[0]).toEqual([["z", "a", "b"]]);
  });

  // Rows picked on another page stay picked when this page is let go.
  it("lets go of the rows on screen only", async () => {
    const wrapper = await mountBar({
      selectable: true,
      recordIds: ["a", "b"],
      selected: ["z", "a", "b"],
    });

    expect(selectAll(wrapper).props("modelValue")).toBe(true);

    selectAll(wrapper).vm.$emit("update:modelValue", false);

    expect(wrapper.emitted("update:selected")?.[0]).toEqual([["z"]]);
  });

  it("shows the bulk actions once a row is picked", async () => {
    const wrapper = await mountBar({
      selectable: true,
      recordIds: ["a"],
      selected: ["a"],
    });

    expect(wrapper.text()).toContain("bulk actions");
  });
});
