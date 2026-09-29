<script lang="ts">
export default {
  name: "ViewInArBtn",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { arMode, openInAr } from "@/frontend/utils/arViewer";
import type { Model } from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { displayAlert } = useAppNotifications();

const mode = arMode();

const holoUrl = computed(() => props.model.media.holo?.url);

// Only a holo exported in meters can be placed at true size.
const visible = computed(
  () => !!mode && !!holoUrl.value && !!props.model.holoToScale,
);

const opening = ref(false);

const open = async () => {
  if (!mode || !holoUrl.value) {
    return;
  }

  opening.value = true;

  try {
    await openInAr(holoUrl.value, mode);
  } catch {
    displayAlert({ text: t("messages.error.default") });
  } finally {
    opening.value = false;
  }
};
</script>

<template>
  <Btn
    v-if="visible"
    v-tooltip="t('labels.viewInArHint')"
    :loading="opening"
    :aria-label="t('labels.viewInArHint')"
    data-test="view-in-ar"
    @click="open"
  >
    <i class="fa-light fa-cube" />
    {{ t("labels.viewInAr") }}
  </Btn>
</template>
