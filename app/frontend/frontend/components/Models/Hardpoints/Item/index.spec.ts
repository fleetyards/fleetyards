import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it } from "vitest";
import Component from "./index.vue";

// jsdom lays nothing out, so where each part sits is given here: the headline
// at `headlineTop`, everything else on the first line.
const placeHeadline = (headlineTop: number) => {
  const top = Object.getOwnPropertyDescriptor(
    HTMLElement.prototype,
    "offsetTop",
  );
  const height = Object.getOwnPropertyDescriptor(
    HTMLElement.prototype,
    "offsetHeight",
  );

  Object.defineProperty(HTMLElement.prototype, "offsetTop", {
    configurable: true,
    get() {
      return (this as HTMLElement).classList.contains("hardpoint-headline")
        ? headlineTop
        : 0;
    },
  });
  Object.defineProperty(HTMLElement.prototype, "offsetHeight", {
    configurable: true,
    get: () => 20,
  });

  return () => {
    if (top) Object.defineProperty(HTMLElement.prototype, "offsetTop", top);
    if (height) {
      Object.defineProperty(HTMLElement.prototype, "offsetHeight", height);
    }
  };
};

let restore: (() => void) | undefined;

afterEach(() => restore?.());

const mount = () =>
  mountWithDefaults(Component, {
    props: { count: 4 },
    slots: {
      default: () => [
        h("span", { class: "name" }, "Gimbal Mount"),
        h("div", { class: "hardpoint-headline" }, "80 °/s"),
      ],
    },
  });

describe("HardpointItemWrapper", () => {
  it("lets a headline on a line of its own run to the row's edge", async () => {
    restore = placeHeadline(40);

    const wrapper = await mount();
    await nextTick();

    expect(wrapper.get(".hardpoint-item__inner").classes()).toContain(
      "hardpoint-item__inner--wrapped",
    );
  });

  it("keeps the rail in the row while the headline shares the first line", async () => {
    restore = placeHeadline(0);

    const wrapper = await mount();
    await nextTick();

    expect(wrapper.get(".hardpoint-item__inner").classes()).not.toContain(
      "hardpoint-item__inner--wrapped",
    );
  });
});
