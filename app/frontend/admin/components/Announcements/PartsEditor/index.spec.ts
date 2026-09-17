import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { describe, expect, it } from "vitest";
import Component from "./index.vue";

const limits = [
  { label: "X", limit: 280, counter: "x" as const },
  { label: "Bluesky", limit: 300, counter: "bluesky" as const },
];

describe("AnnouncementPartsEditor", () => {
  it("renders one row per part", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "social-parts", label: "Posts", modelValue: ["a", "b"] },
    });

    expect(wrapper.findAll("[data-test='parts-editor-part']")).toHaveLength(2);
  });

  it("adds an empty part", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "social-parts", label: "Posts", modelValue: ["a"] },
    });

    await wrapper.find("[data-test='parts-editor-add']").trigger("click");

    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([["a", ""]]);
  });

  it("removes the part at the position asked for, not the last one", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        name: "social-parts",
        label: "Posts",
        modelValue: ["a", "b", "c"],
      },
    });

    await wrapper
      .findAll("[data-test='parts-editor-remove']")[1]
      .trigger("click");

    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([["a", "c"]]);
  });

  // Where a thread breaks is editorial, so the order has to be movable after
  // the fact.
  it("moves a part up", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { name: "social-parts", label: "Posts", modelValue: ["a", "b"] },
    });

    await wrapper.findAll("[data-test='parts-editor-up']")[1].trigger("click");

    expect(wrapper.emitted("update:modelValue")?.at(-1)).toEqual([["b", "a"]]);
  });

  /*
   * X bills a URL at 23 characters whatever its real length, so counting plain
   * characters would tell an author a post is over when it is not.
   */
  it("counts a URL the way X does, and plainly for Bluesky", async () => {
    const link = "https://fleetyards.net/a/rather/long/path/to/somewhere";
    const wrapper = await mountWithDefaults(Component, {
      props: {
        name: "social-parts",
        label: "Posts",
        modelValue: [`Read on ${link}`],
        limits,
      },
    });

    const counts = wrapper.findAll(
      "[data-test='parts-editor-part'] .parts-editor__count",
    );

    expect(counts[0].text()).toContain(`${8 + 23}/280`);
    expect(counts[1].text()).toContain(`${8 + link.length}/300`);
  });

  // Two or more parts are a thread, and the form says so.
  it("draws the thread rail only once there is more than one part", async () => {
    const one = await mountWithDefaults(Component, {
      props: { name: "social-parts", label: "Posts", modelValue: ["a"] },
    });
    const two = await mountWithDefaults(Component, {
      props: { name: "social-parts", label: "Posts", modelValue: ["a", "b"] },
    });

    expect(one.find(".parts-editor--threaded").exists()).toBe(false);
    expect(two.find(".parts-editor--threaded").exists()).toBe(true);
    // The first part is the head of the thread, not a reply to anything.
    expect(two.findAll(".parts-editor__reply")).toHaveLength(1);
  });

  /*
   * The composer prepends a position marker to every Discord message in a run
   * of two or more, and Discord counts it. A counter that ignored it would
   * offer the full 2,000 on a message that then bounces.
   */
  it("counts the Discord position marker once the run is a thread", async () => {
    const body = "x".repeat(100);
    const discord = [
      { label: "Discord", limit: 2000, counter: "discord" as const },
    ];

    const one = await mountWithDefaults(Component, {
      props: {
        name: "discord-parts",
        label: "Messages",
        modelValue: [body],
        limits: discord,
      },
    });
    const two = await mountWithDefaults(Component, {
      props: {
        name: "discord-parts",
        label: "Messages",
        modelValue: [body, body],
        limits: discord,
      },
    });

    expect(one.find(".parts-editor__count").text()).toContain("100/2000");
    expect(two.find(".parts-editor__count").text()).toContain("109/2000");
  });

  it("marks a part that is over its limit", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        name: "social-parts",
        label: "Posts",
        modelValue: ["x".repeat(290)],
        limits,
      },
    });

    const counts = wrapper.findAll(
      "[data-test='parts-editor-part'] .parts-editor__count",
    );

    expect(counts[0].classes()).toContain("parts-editor__count--over");
    expect(counts[1].classes()).not.toContain("parts-editor__count--over");
  });
});
