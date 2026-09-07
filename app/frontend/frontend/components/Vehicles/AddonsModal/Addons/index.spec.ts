import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { ModelModule, ModelUpgrade } from "@/services/fyApi";

const modul = (id: string, name: string, overrides = {}): ModelModule =>
  ({
    id,
    name,
    slug: name.toLowerCase(),
    media: {},
    availability: { boughtAt: [], soldAt: [] },
    createdAt: "",
    updatedAt: "",
    ...overrides,
  }) as unknown as ModelModule;

const upgrade = (id: string, name: string): ModelUpgrade =>
  ({ id, name, media: {}, createdAt: "", updatedAt: "" }) as ModelUpgrade;

const mount = (props: Record<string, unknown>) =>
  mountWithDefaults(Component, {
    props: {
      addons: [modul("m1", "Cargo"), modul("m2", "Combat")],
      modelValue: [],
      editable: true,
      emptyLabel: "nothing fitted",
      ...props,
    },
  });

const rows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll("[data-test='vehicle-addon']");

describe("VehicleAddonsModalAddons", () => {
  /**
   * The regression this list was rebuilt for: it used to push into a local copy
   * behind a watcher Vue 3 never fires for an in-place mutation, so a click drew
   * a tick and the form saved nothing.
   */
  it("emits the new selection when a row is toggled on", async () => {
    const wrapper = await mount({});

    await rows(wrapper)[0].find("button").trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([[["m1"]]]);
  });

  it("emits the selection without the addon when a fitted row is toggled off", async () => {
    const wrapper = await mount({ modelValue: ["m1", "m2"] });

    await rows(wrapper)[0]
      .find("[data-test='vehicle-addon-toggle']")
      .trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([[["m2"]]]);
  });

  it("keeps every copy a hangar holds of the same addon", async () => {
    const wrapper = await mount({ modelValue: ["m1", "m1"] });

    await rows(wrapper)[0]
      .find("[data-test='vehicle-addon-increase']")
      .trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([
      [["m1", "m1", "m1"]],
    ]);
  });

  it("drops one copy at a time, and cannot step below the last one", async () => {
    const wrapper = await mount({ modelValue: ["m1", "m1"] });
    const decrease = rows(wrapper)[0].find(
      "[data-test='vehicle-addon-decrease']",
    );

    await decrease.trigger("click");
    expect(wrapper.emitted("update:modelValue")).toEqual([[["m1"]]]);

    const single = await mount({ modelValue: ["m1"] });
    expect(
      single
        .findAll("[data-test='vehicle-addon-decrease']")[0]
        .attributes("disabled"),
    ).toBeDefined();
  });

  // The stepper is what a count is edited with, so it has nothing to do on a row
  // holding nothing.
  it("offers a stepper only on a fitted row", async () => {
    const wrapper = await mount({ modelValue: ["m1"] });

    expect(
      wrapper.findAll("[data-test='vehicle-addon-increase']"),
    ).toHaveLength(1);
  });

  it("shows the whole catalogue while editing", async () => {
    const wrapper = await mount({ modelValue: [] });

    expect(rows(wrapper)).toHaveLength(2);
  });

  /**
   * Read-only this is a report of what the ship carries; the rest of the
   * catalogue is not an answer to that, and it cannot be picked anyway.
   */
  it("shows only what is fitted, and no toggle, when it cannot be edited", async () => {
    const wrapper = await mount({ modelValue: ["m2"], editable: false });

    expect(rows(wrapper)).toHaveLength(1);
    expect(wrapper.text()).toContain("Combat");
    expect(wrapper.text()).not.toContain("Cargo");
    expect(wrapper.findAll("[data-test='vehicle-addon-toggle']")).toHaveLength(
      0,
    );
  });

  /**
   * Every row read-only is a fitted one, so the pill would be on all of them.
   * The count is the part that still carries information there, and there is no
   * stepper to read it off.
   */
  it("reports copies instead of a fitted pill when it cannot be edited", async () => {
    const wrapper = await mount({
      modelValue: ["m1", "m1"],
      editable: false,
    });

    expect(wrapper.findAll("[data-test='pill']")).toHaveLength(0);
    expect(wrapper.text()).toContain("2");
    expect(wrapper.find(".addon-option__figure").exists()).toBe(true);
  });

  it("marks a fitted row with a pill while editing", async () => {
    const wrapper = await mount({ modelValue: ["m1"] });

    expect(wrapper.findAll("[data-test='pill']")).toHaveLength(1);
    expect(rows(wrapper)[0].classes()).toContain("addon-option--selected");
  });

  it("says so when a ship carries none of them", async () => {
    const wrapper = await mount({ modelValue: [], editable: false });

    expect(rows(wrapper)).toHaveLength(0);
    expect(wrapper.text()).toContain("nothing fitted");
  });

  // An upgrade kit carries no hardpoints, cargo or production status, so the row
  // has to hold together on a name and a description alone.
  it("renders an upgrade kit, which has no module fields at all", async () => {
    const wrapper = await mount({
      addons: [upgrade("u1", "Idris K Kit")],
      modelValue: ["u1"],
    });

    expect(rows(wrapper)).toHaveLength(1);
    expect(wrapper.text()).toContain("Idris K Kit");
  });
});
