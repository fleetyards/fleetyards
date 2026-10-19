import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, beforeAll, describe, expect, it } from "vitest";
import { type VueWrapper } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required, min } from "@vee-validate/rules";
import Component from "./index.vue";

beforeAll(() => {
  defineRule("required", required);
  defineRule("min", min);
});

const position = (item: unknown) =>
  ({
    id: "pos-1",
    slug: "bulwark--component--units",
    name: "Bulwark",
    category: "component",
    unit: "units",
    netQuantity: 2,
    item,
  }) as never;

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (item: unknown) => {
  wrapper = await mountWithDefaults<typeof Component>(Component, {
    props: { stockItem: position(item), onSave: async () => undefined },
  });

  return wrapper;
};

describe("LogisticsStockItemModal", () => {
  it("keeps a catalogue position's name and category", async () => {
    const subject = await mount({ id: "bulwark", type: "Component" });

    expect(
      subject.find("[data-test='input-name']").attributes("disabled"),
    ).toBeDefined();
    expect(
      subject.findComponent({ name: "BaseSelect" }).props("disabled"),
    ).toBe(true);
  });

  it("renames a free-text position", async () => {
    const subject = await mount(null);

    expect(
      subject.find("[data-test='input-name']").attributes("disabled"),
    ).toBeUndefined();
    expect(
      subject.findComponent({ name: "BaseSelect" }).props("disabled"),
    ).toBe(false);
  });
});
