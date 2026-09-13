import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mountToggle = (props: { modelValue?: boolean; implied?: boolean }) =>
  mountWithDefaults(Component, {
    props: { name: "alliesFleet", modelValue: false, ...props },
  });

const checked = (wrapper: Awaited<ReturnType<typeof mountToggle>>) =>
  (wrapper.find("input").element as HTMLInputElement).checked;

/*
 * `implied` is how a narrower audience switch says what is actually true of it
 * while a wider one covers it: a fleet that is public is visible to its allies,
 * so "ships visible to allies" reading off -- greyed or not -- says the
 * opposite. It must stay display-only, or turning the public switch back off
 * would hand the allies a setting nobody chose.
 */
describe("FormToggle", () => {
  it("reads as on while a wider switch implies it", async () => {
    const wrapper = await mountToggle({ implied: true });

    expect(checked(wrapper)).toBe(true);
  });

  it("keeps the value it holds rather than the one it shows", async () => {
    const wrapper = await mountToggle({ implied: true });

    expect(wrapper.emitted("update:modelValue")).toBeUndefined();
  });

  it("goes back to its own value once nothing implies it", async () => {
    const wrapper = await mountToggle({ implied: true });

    await wrapper.setProps({ implied: false });

    expect(checked(wrapper)).toBe(false);
  });

  // The emit is the only path a parent's own `v-model` has, and it used to ride
  // on the element's `v-model`, which `implied` replaced.
  it("still tells its parent what was pressed", async () => {
    const wrapper = await mountToggle({});

    await wrapper.find("input").setValue(true);

    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([true]);
  });
});
