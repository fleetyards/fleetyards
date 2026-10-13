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
import { downloadPlaque } from "@/frontend/components/Vehicles/Plaque/download";

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

const download = async () => {
  const element = document.getElementById(props.element);
  if (!element) {
    return;
  }

  downloading.value = true;

  await downloadPlaque(element, props.filename)
    .catch(() => {
      displayAlert({ text: t("messages.vehiclePlaque.downloadFailure") });
    })
    .finally(() => {
      downloading.value = false;
    });
};
</script>

<template>
  <Btn
    v-tooltip="withLabel ? undefined : t('actions.saveScreenshot')"
    :loading="downloading"
    :aria-label="t('actions.saveScreenshot')"
    :variant="variant"
    :size="size"
    @click="download"
  >
    <i class="fa-duotone fa-image" />
    <span v-if="withLabel">{{ t("actions.saveScreenshot") }}</span>
  </Btn>
</template>
