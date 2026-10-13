import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import { VueDatePicker } from "@vuepic/vue-datepicker";
import Component from "./index.vue";

const mountPicker = (props: InstanceType<typeof Component>["$props"]) =>
  mountWithDefaults(Component, { props });

const picker = (wrapper: Awaited<ReturnType<typeof mountPicker>>) =>
  wrapper.findComponent(VueDatePicker);

describe("FormDatePicker", () => {
  it("shows the value in the years it is offset by", async () => {
    const wrapper = await mountPicker({
      name: "launchedOn",
      modelValue: "2026-10-14",
      yearOffset: 930,
    });

    const shown = picker(wrapper).props("modelValue") as Date;

    expect(shown.getFullYear()).toBe(2956);
    expect(shown.getMonth()).toBe(9);
    expect(shown.getDate()).toBe(14);
  });

  it("keeps the picked date in real time", async () => {
    const wrapper = await mountPicker({
      name: "launchedOn",
      yearOffset: 930,
    });

    picker(wrapper).vm.$emit("update:model-value", new Date(2956, 2, 5));

    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([
      "2026-03-05",
    ]);
  });

  it("opens an empty picker on today in the offset years", async () => {
    const wrapper = await mountPicker({
      name: "launchedOn",
      yearOffset: 930,
    });

    const start = picker(wrapper).props("startDate") as Date;

    expect(start.getFullYear()).toBe(new Date().getFullYear() + 930);
    expect(picker(wrapper).props("yearRange")).toEqual([2830, 3030]);
  });

  it("moves 29 February to the 28th in a year without one", async () => {
    const wrapper = await mountPicker({
      name: "launchedOn",
      modelValue: "2028-02-29",
      yearOffset: 930,
    });

    const shown = picker(wrapper).props("modelValue") as Date;

    expect(shown.getFullYear()).toBe(2958);
    expect(shown.getMonth()).toBe(1);
    expect(shown.getDate()).toBe(28);
  });

  it("leaves the value alone without an offset", async () => {
    const wrapper = await mountPicker({
      name: "launchedOn",
      modelValue: "2026-10-14",
    });

    expect((picker(wrapper).props("modelValue") as Date).getFullYear()).toBe(
      2026,
    );
    expect(picker(wrapper).props("startDate")).toBeUndefined();
  });
});
