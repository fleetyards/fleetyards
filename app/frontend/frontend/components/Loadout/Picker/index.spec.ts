import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import type { LoadoutPickerOption, LoadoutPickerSort } from "./types";

const MANUFACTURERS = ["Behring", "Klaus & Werner", "Hurston Dynamics"];

// A weapon slot's worth of options: 90, three makers, a few owned or stock.
const MANY: LoadoutPickerOption[] = Array.from({ length: 90 }, (_, index) => ({
  id: `gun-${index}`,
  name: `Gun ${String(index).padStart(2, "0")}`,
  manufacturer: MANUFACTURERS[index % 3],
  owned: index % 30 === 0,
  stock: index === 7,
  sortValues: { dps: (index * 37) % 101 },
}));

const SORTS: LoadoutPickerSort[] = [{ key: "dps", label: "DPS" }];

type Props = {
  title?: string;
  options?: LoadoutPickerOption[];
  selectedId?: string;
  sorts?: LoadoutPickerSort[];
  clearable?: boolean;
};

const mount = (props: Props = {}, attachTo?: Element) =>
  mountWithDefaults(Component, {
    props: { title: "Left wing", options: MANY, ...props },
    attachTo,
  });

type Wrapper = Awaited<ReturnType<typeof mount>>;

const names = (wrapper: Wrapper) =>
  wrapper
    .findAll("[data-test='loadout-picker-option'] .loadout-picker__name")
    .map((name) => name.text());

const selectFor = (wrapper: Wrapper, name: string) =>
  wrapper
    .findAllComponents(BaseSelect)
    .find((select) => select.props("name") === name);

describe("LoadoutPicker", () => {
  it("lists every option, by name, with the total", async () => {
    const wrapper = await mount();

    expect(names(wrapper)).toHaveLength(90);
    expect(names(wrapper)[0]).toBe("Gun 00");
    expect(wrapper.get("[data-test='loadout-picker-count']").text()).toContain(
      "90 options",
    );
  });

  it("narrows the list to what the search matches, by name or maker", async () => {
    const wrapper = await mount();

    await wrapper
      .get("[data-test='loadout-picker-search'] input")
      .setValue("gun 4");
    expect(names(wrapper)).toEqual(
      Array.from({ length: 10 }, (_, i) => `Gun 4${i}`),
    );
    expect(wrapper.get("[data-test='loadout-picker-count']").text()).toContain(
      "10 of 90",
    );

    await wrapper
      .get("[data-test='loadout-picker-search'] input")
      .setValue("klaus");
    expect(names(wrapper)).toHaveLength(30);
  });

  it("says so when nothing matches, and resets every filter in one go", async () => {
    const wrapper = await mount();

    await wrapper
      .get("[data-test='loadout-picker-search'] input")
      .setValue("no such gun");
    expect(
      wrapper.find("[data-test='loadout-picker-no-matches']").exists(),
    ).toBe(true);

    await wrapper.get("[data-test='loadout-picker-reset']").trigger("click");
    expect(names(wrapper)).toHaveLength(90);
  });

  it("keeps owned and stock options together when both are asked for", async () => {
    const wrapper = await mount();

    await wrapper
      .get("[data-test='loadout-picker-owned'] button")
      .trigger("click");
    expect(names(wrapper)).toEqual(["Gun 00", "Gun 30", "Gun 60"]);

    await wrapper
      .get("[data-test='loadout-picker-stock'] button")
      .trigger("click");
    expect(names(wrapper)).toEqual(["Gun 00", "Gun 07", "Gun 30", "Gun 60"]);
  });

  it("offers ownership filters only where an option has that ownership", async () => {
    const wrapper = await mount({
      options: MANY.map(
        ({ owned: _owned, stock: _stock, ...option }) => option,
      ),
    });

    expect(wrapper.find("[data-test='loadout-picker-owned']").exists()).toBe(
      false,
    );
    expect(wrapper.find("[data-test='loadout-picker-stock']").exists()).toBe(
      false,
    );
  });

  it("filters by maker, offered only where there is more than one", async () => {
    const wrapper = await mount();

    selectFor(wrapper, "loadout-picker-manufacturer")?.vm.$emit(
      "update:modelValue",
      "Behring",
    );
    await nextTick();
    expect(names(wrapper)).toHaveLength(30);

    const single = await mount({
      options: MANY.slice(0, 3).map((option) => ({
        ...option,
        manufacturer: "Behring",
      })),
    });
    expect(selectFor(single, "loadout-picker-manufacturer")).toBeUndefined();
  });

  it("sorts by the caller's figure, highest first, and keeps unscored ones last", async () => {
    const options = [
      { id: "a", name: "Alpha", sortValues: { dps: 10 } },
      { id: "b", name: "Bravo" },
      { id: "c", name: "Charlie", sortValues: { dps: 30 } },
    ];
    const wrapper = await mount({ options, sorts: SORTS });

    expect(names(wrapper)).toEqual(["Charlie", "Alpha", "Bravo"]);

    selectFor(wrapper, "loadout-picker-sort")?.vm.$emit(
      "update:modelValue",
      "name",
    );
    await nextTick();
    expect(names(wrapper)).toEqual(["Alpha", "Bravo", "Charlie"]);
  });

  it("marks what the socket holds and picks another", async () => {
    const wrapper = await mount({ selectedId: "gun-3" });

    const selected = wrapper.findAll(".loadout-picker__option--selected");
    expect(selected).toHaveLength(1);
    expect(selected[0].text()).toContain("Gun 03");

    await wrapper
      .findAll("[data-test='loadout-picker-option']")[5]
      .trigger("click");
    expect(wrapper.emitted("pick")).toEqual([["gun-5"]]);
  });

  it("empties the socket from its own choice, unless the caller forbids it", async () => {
    const wrapper = await mount({ selectedId: "gun-3" });

    await wrapper.get("[data-test='loadout-picker-empty']").trigger("click");
    expect(wrapper.emitted("pick")).toEqual([[null]]);

    const required = await mount({ clearable: false });
    expect(required.find("[data-test='loadout-picker-empty']").exists()).toBe(
      false,
    );
  });

  it("previews what is pointed at and lets go when the pointer leaves", async () => {
    const wrapper = await mount();

    await wrapper
      .findAll("[data-test='loadout-picker-option']")[2]
      .trigger("mouseenter");
    await wrapper
      .get("[data-test='loadout-picker-empty']")
      .trigger("mouseenter");
    await wrapper
      .get("[data-test='loadout-picker-options']")
      .trigger("mouseleave");

    expect(wrapper.emitted("preview")).toEqual([["gun-2"], [null]]);
    expect(wrapper.emitted("previewEnd")).toHaveLength(1);
  });

  it("closes on Escape and from its close button", async () => {
    const wrapper = await mount();

    await wrapper
      .get("[data-test='loadout-picker-search'] input")
      .trigger("keydown", { key: "Escape" });
    await wrapper.get("[data-test='loadout-picker-close']").trigger("click");

    expect(wrapper.emitted("close")).toHaveLength(2);
  });

  it("shows a figure and the change it makes", async () => {
    const wrapper = await mount({
      options: [
        {
          id: "cargo",
          name: "Cargo Module",
          figure: "32 SCU",
          delta: { label: "+16 SCU", tone: "better" },
        },
      ],
    });

    const delta = wrapper.get("[data-test='loadout-picker-delta']");
    expect(delta.text()).toBe("+16 SCU");
    expect(delta.classes()).toContain("loadout-picker__delta--better");
    expect(wrapper.text()).toContain("32 SCU");
  });

  it("puts its search under the caller's focus", async () => {
    const host = document.createElement("div");
    document.body.appendChild(host);
    const wrapper = await mount({}, host);

    (wrapper.vm as unknown as { focusSearch: () => void }).focusSearch();

    expect(document.activeElement?.tagName).toBe("INPUT");

    wrapper.unmount();
    host.remove();
  });

  it("renders the caller's comparison under the list", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { title: "Left wing", options: MANY },
      slots: { comparison: () => h("p", { "data-test": "comparison" }, "x") },
    });

    expect(
      wrapper
        .find(".loadout-picker__comparison [data-test='comparison']")
        .exists(),
    ).toBe(true);
  });
});
