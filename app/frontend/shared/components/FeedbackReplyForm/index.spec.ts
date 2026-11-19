import { describe, expect, it, vi } from "vitest";
import { flushPromises } from "@vue/test-utils";
import { defineRule } from "vee-validate";
import { required } from "@vee-validate/rules";
import { mountWithDefaults } from "@/shared/utils/TestUtils";
import Component from "./index.vue";

defineRule("required", required);

const mount = (send: (body: string) => Promise<void>) =>
  mountWithDefaults(Component, {
    props: { label: "Reply", submitLabel: "Send", maxlength: 5000, send },
  });

describe("FeedbackReplyForm", () => {
  it("sends the trimmed reply and clears the field", async () => {
    const send = vi.fn(() => Promise.resolve());
    const wrapper = await mount(send);
    const textarea = wrapper.find('[data-test="feedback-reply-body"] textarea');

    await textarea.setValue("  The Carrack  ");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(send).toHaveBeenCalledWith("The Carrack");
    expect((textarea.element as HTMLTextAreaElement).value).toBe("");
  });

  it("keeps what was typed when sending fails", async () => {
    const wrapper = await mount(() => Promise.reject(new Error("nope")));
    const textarea = wrapper.find('[data-test="feedback-reply-body"] textarea');

    await textarea.setValue("The Carrack");
    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect((textarea.element as HTMLTextAreaElement).value).toBe("The Carrack");
  });

  it("sends nothing empty", async () => {
    const send = vi.fn(() => Promise.resolve());
    const wrapper = await mount(send);

    await wrapper.find("form").trigger("submit");
    await flushPromises();

    expect(send).not.toHaveBeenCalled();
  });
});
