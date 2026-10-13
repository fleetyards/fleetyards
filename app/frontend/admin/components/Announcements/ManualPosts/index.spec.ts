import { describe, expect, it, vi } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import copyText from "@/shared/utils/CopyText";
import Component from "./index.vue";

vi.mock("@/shared/utils/CopyText", () => ({
  default: vi.fn(() => Promise.resolve()),
}));

describe("AnnouncementManualPosts", () => {
  it("lists each post in order, line breaks kept", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { posts: ["One\n\nhttps://fleetyards.net", "Two"] },
    });

    const posts = wrapper.findAll("[data-test='announcement-manual-post'] pre");

    expect(posts.map((post) => post.text())).toEqual([
      "One\n\nhttps://fleetyards.net",
      "Two",
    ]);
  });

  it("copies the post its button sits under", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { posts: ["One", "Two"] },
    });

    await wrapper
      .findAll("[data-test='announcement-manual-post-copy']")[1]
      .trigger("click");

    expect(copyText).toHaveBeenCalledWith("Two");
  });
});
