import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const mount = (props?: { count?: number }) =>
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

  it("keeps the placeholders out of the reading order", async () => {
    const wrapper = await mount({ count: 2 });

    expect(
      wrapper.get('[data-test="list-skeleton"]').attributes("aria-hidden"),
    ).toBe("true");
  });
});
