import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mount = (props?: { count?: number; selectable?: boolean }) =>
  mountWithDefaults<typeof Component>(Component, { props });

const items = (wrapper: Awaited<ReturnType<typeof mount>>) =>
  wrapper.findAll(".list-skeleton__item");

describe("ListSkeleton", () => {
  it("renders one placeholder per row the page will hold", async () => {
    const wrapper = await mount({ count: 6 });

    expect(items(wrapper)).toHaveLength(6);
  });

  // A list that has been seen empty reserves nothing: a count of zero is an
  // answer, and the `10` below is only for a list nobody has seen yet.
  it("reserves nothing for a list known to be empty", async () => {
    const wrapper = await mount({ count: 0 });

    expect(items(wrapper)).toHaveLength(0);
  });

  it("falls back to a page of rows before anything is known", async () => {
    const wrapper = await mount();

    expect(items(wrapper)).toHaveLength(10);
  });

  // The checkbox takes the row's left inset over from the title, so a
  // placeholder without one stands the icon and both lines 35px left of where
  // they land - the whole row sliding sideways as the records arrive.
  it("carries a checkbox where the rows it waits for do", async () => {
    const wrapper = await mount({ count: 3, selectable: true });

    expect(
      wrapper.findAll('[data-test="list-skeleton-checkbox"]'),
    ).toHaveLength(3);
    expect(items(wrapper)[0].classes()).toContain(
      "list-skeleton__item--selectable",
    );
  });

  it("leaves it out for a list whose rows have none", async () => {
    const wrapper = await mount({ count: 3 });

    expect(
      wrapper.findAll('[data-test="list-skeleton-checkbox"]'),
    ).toHaveLength(0);
    expect(items(wrapper)[0].classes()).not.toContain(
      "list-skeleton__item--selectable",
    );
  });

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount({ count: 2 });

    expect(
      wrapper.get('[data-test="list-skeleton"]').attributes("aria-hidden"),
    ).toBe("true");
  });
});
