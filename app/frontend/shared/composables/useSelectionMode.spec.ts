import { describe, expect, it } from "vitest";
import { nextTick, ref } from "vue";

import { useSelectionMode } from "./useSelectionMode";

const setup = (phone = true) => {
  const count = ref(0);
  const mobile = ref(phone);

  return { count, mobile, mode: useSelectionMode(count, mobile) };
};

describe("useSelectionMode", () => {
  it("starts on a phone", () => {
    const { mode } = setup();

    mode.start();

    expect(mode.selecting.value).toBe(true);
  });

  it("has no mode to be in off a phone", () => {
    const { mode } = setup(false);

    mode.start();

    expect(mode.selecting.value).toBe(false);
  });

  it("ends once nothing is picked any more", async () => {
    const { count, mode } = setup();

    count.value = 1;
    mode.start();
    await nextTick();

    expect(mode.selecting.value).toBe(true);

    count.value = 0;
    await nextTick();

    expect(mode.selecting.value).toBe(false);
  });

  it("survives the first pick landing after it started", async () => {
    const { count, mode } = setup();

    mode.start();
    count.value = 1;
    await nextTick();

    expect(mode.selecting.value).toBe(true);
  });

  it("ends when the window grows past a phone", async () => {
    const { count, mobile, mode } = setup();

    count.value = 2;
    mode.start();
    mobile.value = false;
    await nextTick();
    mobile.value = true;
    await nextTick();

    expect(mode.selecting.value).toBe(false);
  });
});
