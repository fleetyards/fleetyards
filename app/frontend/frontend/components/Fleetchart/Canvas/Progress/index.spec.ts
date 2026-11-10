import { describe, expect, it, vi } from "vitest";
import { mount } from "@vue/test-utils";
import { nextTick } from "vue";
import FleetchartCanvasProgress from "./index.vue";
import { createImageProgress } from "@/frontend/components/Fleetchart/imageProgress";
import { createExportProgress } from "@/frontend/components/Fleetchart/exportProgress";

vi.mock("@/shared/composables/useI18n", () => ({
  useI18n: () => ({
    t: (key: string, options?: Record<string, string>) =>
      options ? `${key} ${options.loaded}/${options.total}` : key,
    currentLocale: () => "en",
  }),
}));

const setup = () => {
  const images = createImageProgress();
  const exportProgress = createExportProgress();
  const wrapper = mount(FleetchartCanvasProgress, {
    props: { images, exportProgress },
    global: {
      stubs: {
        ProgressBar: {
          props: ["progress"],
          template: "<progress :value='progress' />",
        },
      },
    },
  });

  return { images, exportProgress, wrapper };
};

describe("FleetchartCanvasProgress", () => {
  it("is not there while nothing loads", () => {
    const { wrapper } = setup();

    expect(wrapper.find("[role='status']").exists()).toBe(false);
  });

  it("counts the chart's pictures", async () => {
    const { images, wrapper } = setup();

    images.pending("a");
    images.pending("b");
    images.settled("a");
    await nextTick();

    expect(wrapper.text()).toBe("labels.fleetchartApp.loadingPictures 1/2");
    expect(wrapper.get("progress").attributes("value")).toBe("50");
  });

  it("takes over for an export, counting its pictures, then drawing and saving", async () => {
    const { images, exportProgress, wrapper } = setup();

    images.pending("a");
    exportProgress.start(4);
    exportProgress.pictureReady();
    await nextTick();

    expect(
      wrapper.find("[data-test='fleetchart-export-progress']").text(),
    ).toBe("labels.fleetchartApp.exportPictures 1/4");
    expect(wrapper.get("progress").attributes("value")).toBe("25");

    exportProgress.stage.value = "drawing";
    await nextTick();

    expect(wrapper.text()).toBe("labels.fleetchartApp.exportDrawing");
    expect(wrapper.find("progress").exists()).toBe(false);
    expect(wrapper.find(".fleetchart-canvas-progress__working").exists()).toBe(
      true,
    );

    exportProgress.stage.value = "saving";
    await nextTick();

    expect(wrapper.text()).toBe("labels.fleetchartApp.exportSaving");

    exportProgress.finish();
    images.settled("a");
    await nextTick();

    expect(wrapper.find("[role='status']").exists()).toBe(false);
  });
});
