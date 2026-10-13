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
} from "@/frontend/components/Vehicles/Plaque/download";

type Props = {
  // The plaque's element id.
  element: string;
  filename: string;
  withLabel?: boolean;
  variant?: `${BtnVariantsEnum}`;
  size?: `${BtnSizesEnum}`;
};

const props = withDefaults(defineProps<Props>(), {
  withLabel: true,
  variant: undefined,
  size: undefined,
});

const { t } = useI18n();
const { displayAlert } = useAppNotifications();

const downloading = ref(false);

// Safari opens the share sheet only right after a tap, and drawing the plaque
// can take longer than that. A refused share keeps the picture, and the next
// tap shares it at once.
const ready = ref<File>();

const save = async (file: File) => {
  try {
    await savePlaque(file);
    ready.value = undefined;
  } catch (error) {
    if (error instanceof DOMException && error.name === "NotAllowedError") {
      ready.value = file;
    } else if (!(
      error instanceof DOMException && error.name === "AbortError"
    )) {
      ready.value = undefined;
      displayAlert({ text: t("messages.vehiclePlaque.downloadFailure") });
    }
  }
};

const download = async () => {
  if (ready.value) {
    await save(ready.value);
    return;
  }

  const element = document.getElementById(props.element);
  if (!element) {
    return;
  }

  downloading.value = true;

  const file = await plaqueFile(element, props.filename)
    .catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.downloadFailure") });
    })
    .finally(() => {
      downloading.value = false;
    });

  if (file) {
    await save(file);
  }
};

const label = computed(() =>
  ready.value ? t("actions.share") : t("actions.saveScreenshot"),
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
    <i v-if="ready" class="fa-duotone fa-share-square" />
    <i v-else class="fa-duotone fa-image" />
    <span v-if="withLabel">{{ label }}</span>
  </Btn>
</template>
