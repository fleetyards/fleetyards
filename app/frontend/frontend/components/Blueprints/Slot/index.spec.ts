import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mount = async (quality: number) => {
  wrapper = await mountWithDefaults(Component, {
    props: {
      slotData: {
        position: 1,
        name: "Frame",
        options: [],
        modifiers: [],
      } as never,
      quality,
      ramps: false,
      links: false,
    },
  });

  return wrapper;
};

describe("BlueprintSlot", () => {
  // A grade is 0 to 1000, and the field says so even where the grade it
  // settles on is the one already held, which re-renders nothing.
  it.each([
    ["5000", "1000"],
    ["-40", "0"],
  ])("holds a typed %s to %s", async (typed, held) => {
    const subject = await mount(Number(held));
    const input = subject.find("input[type='number']");

    await input.setValue(typed);

    expect((input.element as HTMLInputElement).value).toBe(held);
    expect(subject.emitted("update:quality")?.at(-1)).toEqual([Number(held)]);
  });

  it("takes a grade within the range as typed", async () => {
    const subject = await mount(500);
    const input = subject.find("input[type='number']");

    await input.setValue("750");

    expect((input.element as HTMLInputElement).value).toBe("750");
    expect(subject.emitted("update:quality")?.at(-1)).toEqual([750]);
  });
});
