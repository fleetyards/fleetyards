<template>
  <Btn
    v-tooltip="tooltip"
    :loading="downloading"
    :aria-label="t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click="download"
  >
    <SmallLoader :loading="downloading" />
    <i class="fad fa-image" />
    <span v-if="withLabel">
      {{ t("actions.saveScreenshot") }}
    </span>
  </Btn>
</template>

<script lang="ts" setup>
import html2canvas from "html2canvas";
import downloadJs from "downloadjs";
import Btn from "@/shared/components/base/Btn/index.vue";
import SmallLoader from "@/shared/components/SmallLoader/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";

type Props = {
  element: string;
  withLabel?: boolean;
  filename?: string;
  variant?: BtnVariantsEnum;
  size?: BtnSizesEnum;
  inline?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
  variant: BtnVariantsEnum.DEFAULT,
  size: BtnSizesEnum.DEFAULT,
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

  if (!element) {
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

<script lang="ts">
export default {
  name: "DownloadScreenshotBtn",
};
</script>

<style lang="scss" scoped>
@import "index";
</style>
