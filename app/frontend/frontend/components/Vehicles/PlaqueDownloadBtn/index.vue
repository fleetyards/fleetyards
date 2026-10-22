<script lang="ts">
export default {
  name: "VehiclePlaqueDownloadBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  plaqueFile,
  savePlaque,
  sharePlaque,
} from "@/frontend/components/Vehicles/Plaque/download";

type Props = {
  // The plaque's element id.
  element: string;
  filename: string;
  withLabel?: boolean;
  // Hands the picture to the share sheet rather than saving it; only offer it
  // where `canSharePlaques` holds.
  share?: boolean;
  shareTitle?: string;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  share: false,
  shareTitle: undefined,
  variant: undefined,
  size: undefined,
});

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const downloading = ref(false);

// Safari opens the share sheet only right after a tap, and drawing the plaque
// can take longer than that. A refused share keeps the picture, and the next
// tap shares it at once; a change to the plaque drops it again.
const ready = ref<File>();

let observer: MutationObserver | undefined;

const keep = (file?: File) => {
  observer?.disconnect();
  observer = undefined;
  ready.value = file;

  const element = file && document.getElementById(props.element);
  if (!element) {
    return;
  }

  observer = new MutationObserver(() => keep());
  observer.observe(element, {
    subtree: true,
    childList: true,
    attributes: true,
    characterData: true,
  });
};

watch(
  () => [props.element, props.filename],
  () => keep(),
);

onBeforeUnmount(() => keep());

const isDomError = (error: unknown, name: string) =>
  error instanceof DOMException && error.name === name;

const save = async (file: File) => {
  const retry = ready.value === file;

  try {
    await (props.share
      ? sharePlaque(file, props.shareTitle)
      : savePlaque(file));
    keep();
  } catch (error) {
    if (isDomError(error, "NotAllowedError") && !retry) {
      keep(file);
    } else {
      keep();
      if (!isDomError(error, "AbortError")) {
        displayAlert({ text: t("messages.vehiclePlaque.downloadFailure") });
      }
    }
  }
};

const download = async () => {
  if (downloading.value) {
    return;
  }

  downloading.value = true;

  try {
    if (ready.value) {
      await save(ready.value);
      return;
    }

    const element = document.getElementById(props.element);
    if (!element) {
      return;
    }

    const file = await plaqueFile(element, props.filename).catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.downloadFailure") });
    });

    if (file) {
      await save(file);
    }
  } finally {
    downloading.value = false;
  }
};

const label = computed(() =>
  ready.value || props.share ? t("actions.share") : t("actions.saveScreenshot"),
);
</script>

<template>
  <Btn
    v-tooltip="withLabel ? undefined : label"
    :loading="downloading"
    :aria-label="label"
    :variant="variant"
    :size="size"
    @click="download"
  >
    <i v-if="ready || share" class="fa-duotone fa-share-square" />
    <i v-else class="fa-duotone fa-image" />
    <span v-if="withLabel">{{ label }}</span>
  </Btn>
</template>
