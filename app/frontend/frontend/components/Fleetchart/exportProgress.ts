import { ref } from "vue";
import type { DownloadScreenshotStage } from "@/frontend/components/DownloadScreenshotBtn/types";

export type FleetchartExportStage = "pictures" | DownloadScreenshotStage;

// Where a PNG export has got to. Read only by the progress indicator, for the
// same reason as the picture count: the chart itself must not re-render on
// every picture.
export const createExportProgress = () => {
  const stage = ref<FleetchartExportStage>();
  const done = ref(0);
  const total = ref(0);

  const start = (count: number) => {
    stage.value = "pictures";
    done.value = 0;
    total.value = count;
  };

  const pictureReady = () => {
    done.value += 1;
  };

  const finish = () => {
    stage.value = undefined;
  };

  return { stage, done, total, start, pictureReady, finish };
};

export type ExportProgress = ReturnType<typeof createExportProgress>;
