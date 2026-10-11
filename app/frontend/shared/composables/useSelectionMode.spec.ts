import { describe, expect, it } from "vitest";
import { ref } from "vue";

import { useSelectionMode } from "./useSelectionMode";

const setup = (phone = true, picked = 0) => {
  const count = ref(picked);
  const mobile = ref(phone);

  return { count, mobile, mode: useSelectionMode(count, mobile) };
};

describe("useSelectionMode", () => {
  it("is on while something is picked on a phone", () => {
    const { count, mode } = setup();

    expect(mode.selecting.value).toBe(false);

    count.value = 1;

    expect(mode.selecting.value).toBe(true);

    count.value = 0;

    expect(mode.selecting.value).toBe(false);
  });

  it("has no mode to be in off a phone", () => {
    const { mode } = setup(false, 3);

    expect(mode.selecting.value).toBe(false);
  });

  it("follows a rotation across the breakpoint with rows still picked", () => {
    const { mobile, mode } = setup(false, 2);

    mobile.value = true;

    expect(mode.selecting.value).toBe(true);
  });
});
