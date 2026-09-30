import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { EditorContent } from "@tiptap/vue-3";
import type { Editor } from "@tiptap/core";
import { DOMWrapper, flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";
import Component from "./index.vue";
import ImageDialog from "./ImageDialog.vue";

// Images load only from the hosts the page names as its own and RSI's.
window.API_ENDPOINT = "https://api.fleetyards.test/v1";
window.FRONTEND_ENDPOINT = "https://fleetyards.test";
window.RSI_ENDPOINT = "https://robertsspaceindustries.com";

// jsdom has neither: an image preview needs an object URL, and ProseMirror
// measures the selection to scroll it into view after an insert.
URL.createObjectURL = vi.fn(() => "blob:preview");
URL.revokeObjectURL = vi.fn();
Range.prototype.getClientRects = () =>
  ({
    length: 0,
    item: () => null,
    [Symbol.iterator]: [][Symbol.iterator],
  }) as unknown as DOMRectList;
Range.prototype.getBoundingClientRect = () => new DOMRect();

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

// The size toolbar floats: the menu plugin moves it and hides it by style.
const sizeToolbar = () =>
  document.querySelector<HTMLElement>(
    '[data-test="markdown-editor-image-size"]',
  );

const sizeToolbarShown = () => {
  const toolbar = sizeToolbar();
  return !!toolbar && toolbar.parentElement?.style.visibility !== "hidden";
};

const sizeButton = (size: string) =>
  new DOMWrapper(
    document.querySelector(
      `[data-test="markdown-editor-image-size-${size}"]`,
    ) as Element,
  );

// The item search waits a moment after typing before it asks.
const waitForSuggestions = async () => {
  await new Promise((resolve) => setTimeout(resolve, 250));
  await flushPromises();
  await nextTick();
};

const suggestion = (slug: string) =>
  document.querySelector(
    `[data-test="markdown-editor-item-suggestion-${slug}"]`,
  );

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
      .find('[data-test="markdown-editor-link-url"] input')
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
      .find('[data-test="markdown-editor-link-url"] input')
      .setValue("javascript:alert(1)");
    await subject
      .find('[data-test="markdown-editor-link-apply"]')
      .trigger("click");

    expect(
      subject.find('[role="alert"].base-markdown-editor__panel-error').exists(),
    ).toBe(true);
    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });

  it("opens the image dialog above the page and inserts what it returns", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Our banner",
    });

    await button(subject, "image").trigger("click");
    await flushPromises();

    const dialog = subject.findComponent(ImageDialog);
    expect(dialog.exists()).toBe(true);
    expect(
      document.body.querySelector('[data-test="markdown-editor-image-dialog"]'),
    ).not.toBeNull();

    dialog.vm.$emit("insert", {
      src: "https://api.fleetyards.test/files/representations/a.webp",
      alt: "Fleet cover",
    });
    await nextTick();

    expect(lastEmitted(subject)).toContain(
      "![Fleet cover](https://api.fleetyards.test/files/representations/a.webp)",
    );

    dialog.vm.$emit("close");
    await nextTick();
    expect(subject.findComponent(ImageDialog).exists()).toBe(false);
  });

  it("closes the image dialog without changing the text", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Our banner",
    });

    await button(subject, "image").trigger("click");
    await flushPromises();
    subject.findComponent(ImageDialog).vm.$emit("close");
    await nextTick();

    expect(subject.findComponent(ImageDialog).exists()).toBe(false);
    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });

  it("does not report a change for focusing the text", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Cargo & mining\n\n- Escort",
    });

    editorOf(subject).commands.focus("end");
    await nextTick();

    expect(subject.emitted("update:modelValue")).toBeUndefined();
  });

  it("hands back the text as it was once an edit is undone", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "Cargo & mining",
    });
    const editor = editorOf(subject);

    editor.commands.focus("end");
    editor.commands.insertContent("!");
    expect(lastEmitted(subject)).toBe("Cargo &amp; mining!");

    editor.commands.undo();

    expect(lastEmitted(subject)).toBe("Cargo & mining");
  });

  it("offers the size of a selected image over it and changes it", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "![cover](https://robertsspaceindustries.com/a.jpg)",
    });
    await nextFrames();

    expect(sizeToolbarShown()).toBe(false);

    editorOf(subject).chain().focus().setNodeSelection(0).run();
    await nextFrames();
    expect(sizeToolbarShown()).toBe(true);

    await sizeButton("50").trigger("click");
    expect(lastEmitted(subject)).toBe(
      "![cover](https://robertsspaceindustries.com/a.jpg){width=50%}",
    );

    await nextFrames();
    expect(sizeButton("50").attributes("aria-pressed")).toBe("true");

    await sizeButton("full").trigger("click");
    expect(lastEmitted(subject)).toBe(
      "![cover](https://robertsspaceindustries.com/a.jpg)",
    );
  });

  it("keeps the size toolbar while keyboard focus is inside it", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "![cover](https://robertsspaceindustries.com/a.jpg)",
    });
    const editor = editorOf(subject);
    editor.chain().focus().setNodeSelection(0).run();
    await nextFrames();

    (sizeButton("50").element as HTMLElement).focus();
    editor.view.dispatch(editor.state.tr.setMeta("probe", true));
    await nextFrames();

    expect(sizeToolbarShown()).toBe(true);
  });

  it("offers no size for an image while disabled", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "![cover](https://robertsspaceindustries.com/a.jpg)",
      disabled: true,
    });

    editorOf(subject).chain().focus().setNodeSelection(0).run();
    await nextFrames();

    expect(sizeToolbarShown()).toBe(false);
  });

  it("offers catalogue items after [* and inserts the one picked", async () => {
    const searchCatalogue = vi.fn(async () => [
      {
        token: "Quantainium",
        name: "Quantainium",
        type: "Commodity",
        slug: "quantainium",
      },
      {
        token: "Raw Quantainium",
        name: "Raw Quantainium",
        type: "Commodity",
        slug: "raw-quantainium",
      },
    ]);
    const subject = await mountEditor({
      name: "description",
      modelValue: "",
      searchCatalogue: searchCatalogue as never,
    });
    const editor = editorOf(subject);

    editor.chain().focus().insertContent("Mine [*quan").run();
    await waitForSuggestions();

    expect(searchCatalogue).toHaveBeenCalledWith("quan");
    expect(suggestion("raw-quantainium")).not.toBeNull();

    editor.view.dom.dispatchEvent(
      new KeyboardEvent("keydown", { key: "ArrowDown", bubbles: true }),
    );
    editor.view.dom.dispatchEvent(
      new KeyboardEvent("keydown", { key: "Enter", bubbles: true }),
    );

    expect(lastEmitted(subject)).toBe("Mine [*Raw Quantainium*]");
  });

  it("opens the item search from the toolbar", async () => {
    const searchCatalogue = vi.fn(async () => []);
    const subject = await mountEditor({
      name: "description",
      modelValue: "",
      searchCatalogue: searchCatalogue as never,
    });

    editorOf(subject).commands.focus();
    await button(subject, "item").trigger("click");
    await waitForSuggestions();

    expect(
      document.querySelector('[data-test="markdown-editor-item-suggestions"]')
        ?.textContent,
    ).toContain("Type an item's name");
  });

  it("closes the link panel when the image dialog opens", async () => {
    const subject = await mountEditor({ name: "description", modelValue: "" });

    await button(subject, "link").trigger("click");
    await button(subject, "image").trigger("click");
    await flushPromises();

    expect(
      subject.find('[data-test="markdown-editor-link-form"]').exists(),
    ).toBe(false);
    expect(subject.findComponent(ImageDialog).exists()).toBe(true);
  });

  it("edits the markdown itself in source mode", async () => {
    const subject = await mountEditor({
      name: "description",
      modelValue: "**Crew**",
    });

    await button(subject, "source").trigger("click");

    const source = subject.find('[data-test="source-description"]');
    expect((source.element as HTMLTextAreaElement).value).toBe("**Crew**");
    expect(button(subject, "bold").attributes("disabled")).toBeDefined();

    await source.setValue("## Crew\n\n- *one*");

    expect(lastEmitted(subject)).toBe("## Crew\n\n- *one*");
  });

  it("shows what the source means when switching back", async () => {
    const subject = await mountEditor({ name: "description", modelValue: "" });

    await button(subject, "source").trigger("click");
    await subject.find('[data-test="source-description"]').setValue("## Crew");
    await button(subject, "source").trigger("click");

    expect(subject.find('[data-test="source-description"]').exists()).toBe(
      false,
    );
    expect(subject.find(".ProseMirror h2").text()).toBe("Crew");
    expect(lastEmitted(subject)).toBe("## Crew");
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
