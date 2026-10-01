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

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
  variant: undefined,
  size: undefined,
  inline: false,
});

const { t } = useI18n();

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

  html2canvas(element, {
    backgroundColor: null,
    useCORS: true,
    windowWidth: parentNode.scrollWidth,
    windowHeight: parentNode.scrollHeight + 100,
  })
    .then((canvas) => {
      element.classList.remove("fleetchart-download");
      downloading.value = false;
      downloadJs(canvas.toDataURL(), `fleetyards-${props.filename}.png`);
    })
    .catch(() => {
      element.classList.remove("fleetchart-download");
      downloading.value = false;
    });
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
