import { mountWithDefaults } from "@/shared/utils/TestUtils";
import { afterEach, describe, expect, it, vi } from "vitest";
import type { VueWrapper } from "@vue/test-utils";
import Component from "./index.vue";

const displaySuccess = vi.fn();

vi.mock("@/shared/composables/useAppNotifications", () => ({
  useAppNotifications: () => ({ displaySuccess }),
}));

let wrapper: VueWrapper | undefined;

afterEach(() => {
  wrapper?.unmount();
  wrapper = undefined;
  displaySuccess.mockClear();
});

const mount = async (processing: string[]) => {
  wrapper = await mountWithDefaults(Component, {
    props: { processing } as never,
  });

  return wrapper;
};

const summary = (subject: VueWrapper) =>
  subject.find(".views-folder-upload__summary");

describe("ViewsFolderUpload", () => {
  // A page opened while the crops run has no folder of its own to list.
  it("lists the views the model is still cropping", async () => {
    const subject = await mount(["topView", "sideView"]);

    expect(summary(subject).exists()).toBe(true);
    expect(subject.findAll(".views-folder-upload__matched li")).toHaveLength(
      2,
    );
    expect(subject.findAll(".fa-spinner-third")).toHaveLength(2);
  });

  it("says so once the last crop has landed", async () => {
    const subject = await mount(["topView"]);

    await subject.setProps({ processing: [] } as never);

    expect(displaySuccess).toHaveBeenCalledTimes(1);
    expect(summary(subject).exists()).toBe(false);
  });

  it("stays quiet when nothing was processing", async () => {
    const subject = await mount([]);

    expect(summary(subject).exists()).toBe(false);
    expect(displaySuccess).not.toHaveBeenCalled();
  });
});
