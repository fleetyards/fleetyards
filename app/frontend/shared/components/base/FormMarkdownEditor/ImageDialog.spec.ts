import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, describe, expect, it, vi } from "vitest";
import { nextTick } from "vue";
import Component from "./ImageDialog.vue";

// Stands in for the direct uploader: the test says when a file has arrived.
vi.mock("@/shared/components/DirectUpload/Uploader/index.vue", async () => {
  const { defineComponent, h } = await import("vue");

  return {
    default: defineComponent({
      name: "DirectUploadUploader",
      emits: ["upload:start", "upload:done", "upload:error", "clear"],
      setup: () => () => h("div", { "data-test": "uploader-stub" }),
    }),
  };
});

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

const mountDialog = async (
  createImage = vi.fn(async () => "https://api.fleetyards.test/files/a.webp"),
) => {
  wrapper = await mountWithDefaults(Component, {
    props: { name: "description", createImage },
  });

  return { subject: wrapper, createImage };
};

const uploaded = async (subject: VueWrapper, signedId = "signed-blob") => {
  const uploader = subject.findComponent({ name: "DirectUploadUploader" });
  uploader.vm.$emit("upload:start", []);
  uploader.vm.$emit("upload:done", [{ blob: { signed_id: signedId } }]);
  await flushPromises();
};

const insertButton = (subject: VueWrapper) =>
  subject.find('[data-test="markdown-editor-image-apply"]');

describe("FormMarkdownEditor ImageDialog", () => {
  it("cannot insert before an image has been uploaded", async () => {
    const { subject } = await mountDialog();

    expect(insertButton(subject).attributes("disabled")).toBeDefined();
  });

  it("inserts the uploaded image with its description", async () => {
    const { subject, createImage } = await mountDialog();

    await uploaded(subject);
    await subject
      .find('[data-test="markdown-editor-image-alt"] input')
      .setValue("Fleet cover");
    await insertButton(subject).trigger("click");
    await flushPromises();

    expect(createImage).toHaveBeenCalledWith("signed-blob");
    expect(subject.emitted("insert")?.[0]).toEqual([
      { src: "https://api.fleetyards.test/files/a.webp", alt: "Fleet cover" },
    ]);
  });

  it("says so when the image cannot be created, and inserts nothing", async () => {
    const { subject } = await mountDialog(
      vi.fn().mockRejectedValue(new Error("400")),
    );

    await uploaded(subject);
    await insertButton(subject).trigger("click");
    await flushPromises();

    expect(subject.find('[role="alert"]').exists()).toBe(true);
    expect(subject.emitted("insert")).toBeUndefined();
  });

  it("shows the reason the server refused the image", async () => {
    const refusal = Object.assign(new Error("400"), {
      isAxiosError: true,
      response: {
        data: {
          code: "validation_error.markdown_image.create",
          message: "Image could not be uploaded.",
          errors: [
            {
              attribute: "base",
              messages: [
                {
                  code: "markdown_image_limit_reached",
                  message: "You have uploaded 100 images in the last 24 hours.",
                },
              ],
            },
          ],
        },
      },
    });
    const { subject } = await mountDialog(vi.fn().mockRejectedValue(refusal));

    await uploaded(subject);
    await insertButton(subject).trigger("click");
    await flushPromises();

    expect(subject.find(".markdown-image-dialog__error").text()).toBe(
      "You have uploaded 100 images in the last 24 hours.",
    );
  });

  it("closes only itself from its close button, after its animation", async () => {
    vi.useFakeTimers();
    const { subject } = await mountDialog();
    vi.runOnlyPendingTimers();
    await nextTick();

    await subject.find(".modal-header .close").trigger("click");
    expect(subject.emitted("close")).toBeUndefined();

    vi.advanceTimersByTime(300);
    expect(subject.emitted("close")).toHaveLength(1);
    vi.useRealTimers();
  });
});
