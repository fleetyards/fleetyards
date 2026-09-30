import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { EditorContent } from "@tiptap/vue-3";
import type { Editor } from "@tiptap/core";
import type { VueWrapper } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { nextTick } from "vue";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mountEditor = async (props: InstanceType<typeof Component>["$props"]) => {
  wrapper = await mountWithDefaults(Component, {
    props,
    attachTo: document.body,
  });

  return wrapper;
};

const editorOf = (subject: VueWrapper) =>
  subject.findComponent(EditorContent).props("editor") as Editor;

const lastEmitted = (subject: VueWrapper) =>
  subject.emitted("update:modelValue")?.at(-1)?.[0];

// The Vue editor publishes its state to templates two animation frames after
// a change.
const nextFrames = async () => {
  for (let frame = 0; frame < 2; frame += 1) {
    await new Promise((resolve) => requestAnimationFrame(resolve));
  }
  await nextTick();
};

const button = (subject: VueWrapper, key: string) =>
  subject.find(`[data-test="markdown-editor-${key}"]`);

describe("FormMarkdownEditor", () => {
  it("shows the markdown it is given", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "**Crew**\n\n- one",
    });

    expect(subject.find(".ProseMirror strong").text()).toBe("Crew");
    expect(subject.find(".ProseMirror ul li").text()).toBe("one");
  });

  it("does not report a change for merely opening the text", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Some [REDACTED] & more",
    });

    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });

  it("emits markdown as the text changes", async () => {
    const subject = await mountEditor({ name: "description", modelValue: "" });

    editorOf(subject).commands.insertContent("Hello");

    expect(lastEmitted(subject)).toBe("Hello");
  });

  it("emits an empty string once everything is deleted", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Hello",
    });

    editorOf(subject).commands.clearContent(true);

    expect(lastEmitted(subject)).toBe("");
  });

  it("bolds the selection and marks the button pressed", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Crew",
    });
    editorOf(subject).commands.selectAll();

    await button(subject, "bold").trigger("click");

    expect(lastEmitted(subject)).toBe("**Crew**");
    await nextFrames();
    expect(button(subject, "bold").attributes("aria-pressed")).toBe("true");
  });

  it("wraps the text in a centre block", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Welcome",
    });
    editorOf(subject).commands.selectAll();

    await button(subject, "center").trigger("click");

    expect(lastEmitted(subject)).toBe(":::center\n\nWelcome\n\n:::");
  });

  it("links the selection to an address it accepts", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "The Fleet",
    });
    editorOf(subject).commands.selectAll();

    await button(subject, "link").trigger("click");
    await subject
      .find('[data-test="markdown-editor-link-url"]')
      .setValue("https://fleetyards.net/fleets/maru/");
    await subject
      .find('[data-test="markdown-editor-link-apply"]')
      .trigger("click");

    expect(lastEmitted(subject)).toBe(
      "[The Fleet](https://fleetyards.net/fleets/maru/)",
    );
    expect(
      subject.find('[data-test="markdown-editor-link-form"]').exists(),
    ).toBe(false);
  });

  it("refuses an address the page would not link", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "click",
    });
    editorOf(subject).commands.selectAll();

    await button(subject, "link").trigger("click");
    await subject
      .find('[data-test="markdown-editor-link-url"]')
      .setValue("javascript:alert(1)");
    await subject
      .find('[data-test="markdown-editor-link-apply"]')
      .trigger("click");

    expect(
      subject.find('[role="alert"].base-markdown-editor__link-error').exists(),
    ).toBe(true);
    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });

  it("takes a new value from outside", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Old",
    });

    await subject.setProps({ modelValue: "## New" });

    expect(subject.find(".ProseMirror h2").text()).toBe("New");
  });

  it("keeps the document when its own change comes back", async () => {
    const subject = await mountEditor({ name: "description", modelValue: "" });
    const editor = editorOf(subject);
    editor.commands.insertContent("Hello");
    const doc = editor.state.doc;

    await subject.setProps({ modelValue: lastEmitted(subject) as string });

    expect(editor.state.doc).toBe(doc);
  });

  it("counts the markdown against the limit in code points", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "🚀 go",
      maxlength: 10,
    });

    expect(subject.find('[data-test="counter-description"]').text()).toBe(
      "4 / 10",
    );
  });

  it("names its toolbar buttons and ties the text to its label", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "",
      label: "Description",
    });

    const buttons = subject.findAll(".base-markdown-editor__action");
    expect(buttons.length).toBeGreaterThan(0);
    buttons.forEach((action) =>
      expect(action.attributes("aria-label")).toBeTruthy(),
    );

    const labelId = subject.find("label").attributes("id");
    expect(subject.find(".ProseMirror").attributes("aria-labelledby")).toBe(
      labelId,
    );
  });

  it("cannot be edited while disabled", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Locked",
      disabled: true,
    });

    expect(subject.find(".ProseMirror").attributes("contenteditable")).toBe(
      "false",
    );
    expect(button(subject, "bold").attributes("disabled")).toBeDefined();
  });
});
