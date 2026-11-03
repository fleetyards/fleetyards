<script lang="ts">
export default {
  name: "CompareModelsLinks",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const erkulUrl = "https://www.erkul.games/calculator";

const spviewerUrl = computed(
  () =>
    `https://www.spviewer.eu/compare?ship=${props.models
      .map((model) => model.scIdentifier)
      .join("&ship=")}`,
);
</script>

<template>
  <Btn
    :href="erkulUrl"
    :aria-label="t('labels.hardpoints.erkul')"
    :size="BtnSizesEnum.SM"
    class="erkul-link"
  >
    <i />
    {{ t("labels.hardpoints.erkul") }}
  </Btn>
  <Btn
    v-tooltip="t('labels.hardpoints.spviewerTitle')"
    :href="spviewerUrl"
    :aria-label="t('labels.hardpoints.spviewer')"
    :size="BtnSizesEnum.SM"
    class="spviewer-link"
  >
    <i />
    {{ t("labels.hardpoints.spviewer") }}
  </Btn>
</template>
