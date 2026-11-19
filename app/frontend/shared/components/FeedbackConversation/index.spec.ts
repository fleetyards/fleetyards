import { describe, expect, it } from "vitest";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

describe("FeedbackConversation", () => {
  it("shows each message with its author, admin replies set apart", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: {
        entries: [
          {
            id: "a",
            body: "Dragging is slow",
            fromAdmin: false,
            author: "You",
            createdAt: "2026-11-19T12:00:00Z",
          },
          {
            id: "b",
            body: "Which ship?",
            fromAdmin: true,
            author: "Fleetyards",
            createdAt: "2026-11-19T13:00:00Z",
          },
        ],
      },
    });

    const entries = wrapper.findAll(
      '[data-test="feedback-conversation-entry"]',
    );

    expect(entries.map((entry) => entry.text())).toEqual([
      expect.stringContaining("Dragging is slow"),
      expect.stringContaining("Which ship?"),
    ]);
    expect(entries[1].text()).toContain("Fleetyards");
    expect(entries[1].classes()).toContain(
      "feedback-conversation__entry--admin",
    );
  });
});
