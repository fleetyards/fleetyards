import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";
import type { ModelModulePackage } from "@/services/fyApi";

const pkg = (
  id: string,
  name: string,
  modules: { id: string; name: string }[],
): ModelModulePackage =>
  ({
    id,
    name,
    modules,
    media: {},
    createdAt: "",
    updatedAt: "",
  }) as unknown as ModelModulePackage;

// The Endeavor's real packages: Olympic Class is the same Bio Dome twice.
const HOPE = pkg("p1", "Hope Class", [
  { id: "med", name: "Medical Bay (2x2)" },
  { id: "landing", name: "Landing (2x1)" },
]);
const OLYMPIC = pkg("p2", "Olympic Class", [
  { id: "bio", name: "Bio Dome (2x1)" },
  { id: "bio", name: "Bio Dome (2x1)" },
]);

const mount = (props: Record<string, unknown>) =>
  mountWithDefaults(Component, {
    props: {
      packages: [HOPE, OLYMPIC],
      modelValue: [],
      editable: true,
      ...props,
    },
  });

const rows = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll("[data-test='vehicle-addon-package']");

const toggle = (wrapper: Awaited<ReturnType<typeof mount>>, index: number) =>
  rows(wrapper)[index].find("[data-test='vehicle-addon-package-toggle']");

describe("AddonsModalPackages", () => {
  /**
   * The regression: this emitted "upate:modelValue", so applying a package was a
   * no-op no matter what the row did.
   */
  it("emits the package's modules when a row is applied", async () => {
    const wrapper = await mount({});

    await toggle(wrapper, 0).trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([
      [["med", "landing"]],
    ]);
  });

  it("carries through a module a package holds twice", async () => {
    const wrapper = await mount({});

    await toggle(wrapper, 1).trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([[["bio", "bio"]]]);
  });

  /**
   * Replaces rather than adds. Adding could not agree with the tick beside it,
   * which is only ever drawn on an exact match.
   */
  it("replaces whatever was already selected", async () => {
    const wrapper = await mount({ modelValue: ["something-else"] });

    await toggle(wrapper, 0).trigger("click");

    expect(wrapper.emitted("update:modelValue")).toEqual([
      [["med", "landing"]],
    ]);
  });

  it("marks the package whose modules are exactly what is selected", async () => {
    const wrapper = await mount({ modelValue: ["landing", "med"] });

    expect(rows(wrapper)[0].classes()).toContain("addon-option--selected");
    expect(rows(wrapper)[1].classes()).not.toContain("addon-option--selected");
  });

  it("marks nothing when the selection is a package plus one more module", async () => {
    const wrapper = await mount({ modelValue: ["med", "landing", "bio"] });

    expect(wrapper.findAll(".addon-option--selected")).toHaveLength(0);
  });

  it("names what the preset fits, counting a module it holds twice", async () => {
    const wrapper = await mount({});

    expect(rows(wrapper)[0].text()).toContain("Medical Bay (2x2) · Landing");
    expect(rows(wrapper)[1].text()).toContain("2 × Bio Dome (2x1)");
  });

  it("shows only the applied package, and no toggle, when it cannot be edited", async () => {
    const wrapper = await mount({
      modelValue: ["bio", "bio"],
      editable: false,
    });

    expect(rows(wrapper)).toHaveLength(1);
    expect(rows(wrapper)[0].text()).toContain("Olympic Class");
    expect(
      wrapper.findAll("[data-test='vehicle-addon-package-toggle']"),
    ).toHaveLength(0);
    // The only row there is the applied one, so the pill saying so is noise.
    expect(wrapper.findAll("[data-test='pill']")).toHaveLength(0);
  });
});
