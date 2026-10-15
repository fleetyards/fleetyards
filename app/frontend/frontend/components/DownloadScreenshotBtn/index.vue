<script lang="ts">
export default {
  name: "DownloadScreenshotBtn",
};
</script>

<script lang="ts" setup>
import html2canvas from "html2canvas";
import downloadJs from "downloadjs";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { reportError } from "@/shared/plugins/Appsignal";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  element: string;
  withLabel?: boolean;
  filename?: string;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
  inline?: boolean;
};

// Past a browser's canvas limit the picture comes back empty: Safari's is 16.7M
// pixels, Firefox's a side of 32767px. A large fleet drawn at the screen's
// pixel ratio passes both, so the scale gives way first. The side is held to
// half of Firefox's, as older mobile browsers stop well before it.
const MAX_CANVAS_AREA = 16_777_216;
const MAX_CANVAS_SIDE = 16_384;

// html2canvas sizes the canvas from the element's box, transform included, so
// a zoomed panzoom chart is measured as it is shown.
const canvasScale = (element: HTMLElement) => {
  const box = element.getBoundingClientRect();
  const width = Math.max(box.width, 1);
  const height = Math.max(box.height, 1);

  return Math.min(
    window.devicePixelRatio || 1,
    Math.sqrt(MAX_CANVAS_AREA / (width * height)),
    MAX_CANVAS_SIDE / Math.max(width, height),
  );
};

const pngBlob = (canvas: HTMLCanvasElement) =>
  new Promise<Blob>((resolve, reject) => {
    canvas.toBlob((blob) => {
      if (blob) {
        resolve(blob);
      } else {
        reject(
          new Error(
            `The fleetchart could not be encoded at ${canvas.width}x${canvas.height}`,
          ),
        );
      }
    }, "image/png");
  });

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
  variant: undefined,
  size: undefined,
  inline: false,
});

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const downloading = ref(false);

const tooltip = computed(() => {
  if (props.withLabel) {
    return undefined;
  }

  return t("actions.saveScreenshot");
});

const download = async () => {
  downloading.value = true;

  const element = document.querySelector(props.element) as HTMLElement;

  // Nothing to capture yet, such as a fleetchart still rendering. The
  // button's loading state is its only indicator, and a loading button cannot
  // be clicked, so it has to end here too.
  if (!element) {
    downloading.value = false;
    return;
  }

  element.classList.add("fleetchart-download");

  const parentNode = element.parentNode as HTMLElement;

  try {
    const canvas = await html2canvas(element, {
      backgroundColor: null,
      useCORS: true,
      scale: canvasScale(element),
      windowWidth: parentNode.scrollWidth,
      windowHeight: parentNode.scrollHeight + 100,
    });

    downloadJs(await pngBlob(canvas), `fleetyards-${props.filename}.png`);
  } catch (error) {
    reportError(error, "DownloadScreenshotBtn#download");
    displayAlert({ text: t("messages.fleetchartScreenshot.failure") });
  } finally {
    element.classList.remove("fleetchart-download");
    downloading.value = false;
  }
};
</script>

<template>
  <Btn
    v-tooltip="tooltip"
    :loading="downloading"
    :aria-label="t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    @click="download"
  >
    <i class="fa-duotone fa-image" />
    <span v-if="withLabel">
      {{ t("actions.saveScreenshot") }}
    </span>
  </Btn>
</template>

<style lang="scss" scoped>
@import "index";
</style>
