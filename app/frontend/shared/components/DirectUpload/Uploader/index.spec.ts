import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { flushPromises, type VueWrapper } from "@vue/test-utils";
import { afterEach, describe, expect, it } from "vitest";
import { fileTypeMap } from "../types";
import Component from "./index.vue";

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
});

// What a browser on Windows hands over for a .glb: no type at all.
const untyped = (name: string) => new File(["glTF"], name, { type: "" });

const select = async (subject: VueWrapper, files: File[]) => {
  const input = subject.find("input[type='file']");
  Object.defineProperty(input.element, "files", { value: files });
  await input.trigger("change");
  await flushPromises();
};

describe("DirectUploadUploader", () => {
  it("accepts a holo the browser reported no type for", async () => {
    wrapper = await mountWithDefaults(Component, {
      props: { multiple: true, allowedTypes: fileTypeMap.holo },
    });

    await select(wrapper, [untyped("holo.glb")]);

    expect(wrapper.emitted("files:rejected")?.[0]).toEqual([[]]);
  });

  it("still rejects an untyped file it cannot place", async () => {
    wrapper = await mountWithDefaults(Component, {
      props: { multiple: true, allowedTypes: fileTypeMap.holo },
    });
    const file = untyped("holo.blend");

    await select(wrapper, [file]);

    expect(wrapper.emitted("files:rejected")?.[0]).toEqual([[file]]);
  });
});
