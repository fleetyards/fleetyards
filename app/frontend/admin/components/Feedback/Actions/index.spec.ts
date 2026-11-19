import { describe, expect, it, vi, beforeEach } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { type Feedback, FeedbackStateEnum } from "@/services/fyAdminApi";

const { resolve, reopen } = vi.hoisted(() => ({
  resolve: vi.fn(() => Promise.resolve({})),
  reopen: vi.fn(() => Promise.resolve({})),
}));

vi.mock("@/services/fyAdminApi", async (importOriginal) => {
  const original =
    await importOriginal<typeof import("@/services/fyAdminApi")>();
  const { ref } = await import("vue");

  return {
    ...original,
    useResolveFeedback: () => ({ mutateAsync: resolve, isPending: ref(false) }),
    useReopenFeedback: () => ({ mutateAsync: reopen, isPending: ref(false) }),
  };
});

import Component from "./index.vue";

const feedback = (state: FeedbackStateEnum): Feedback => ({
  id: "6f0e1c1e-3b0a-4a51-9a35-2f4f0f6f9b10",
  message: "Dragging is slow",
  state,
  userId: "0b5f9c8e-1d2a-4c3b-8e4f-5a6b7c8d9e0f",
  repliesCount: 0,
  createdAt: "2026-11-19T12:00:00Z",
  updatedAt: "2026-11-19T12:00:00Z",
});

describe("AdminFeedbackActions", () => {
  beforeEach(() => {
    resolve.mockClear();
    reopen.mockClear();
  });

  it("resolves open feedback", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { feedback: feedback(FeedbackStateEnum.OPEN) },
    });

    await wrapper.find('[data-test="feedback-resolve"]').trigger("click");
    await flushPromises();

    expect(resolve).toHaveBeenCalledWith({
      id: feedback(FeedbackStateEnum.OPEN).id,
    });
    expect(reopen).not.toHaveBeenCalled();
  });

  it("reopens resolved feedback", async () => {
    const wrapper = await mountWithDefaults(Component, {
      props: { feedback: feedback(FeedbackStateEnum.RESOLVED) },
    });

    await wrapper.find('[data-test="feedback-reopen"]').trigger("click");
    await flushPromises();

    expect(reopen).toHaveBeenCalled();
    expect(resolve).not.toHaveBeenCalled();
  });
});
