<template>
  <Btn
    v-tooltip="!withLabel && t('actions.saveScreenshot')"
    :loading="downloading"
    :aria-label="t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    :inline="inline"
    @click.native="download"
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
import Btn from "@/frontend/core/components/Btn/index.vue";
import type { Props as BtnProps } from "@/frontend/core/components/Btn/index.vue";
import SmallLoader from "@/frontend/core/components/SmallLoader/index.vue";
import { useI18n } from "@/frontend/composables/useI18n";

interface Props extends BtnProps {
  element: string;
  withLabel?: boolean;
  filename?: string;
}

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  filename: "fleetyards-screenshot",
});

const { t } = useI18n();

const downloading = ref(false);

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
