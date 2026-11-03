<script lang="ts">
export default {
  name: "CompareModelsActions",
};
</script>

<script lang="ts" setup>
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import Btn from "@/shared/components/base/Btn/index.vue";
import ShareBtn from "@/frontend/components/ShareBtn/index.vue";
import { useCompareShareUrl } from "@/frontend/composables/useCompareShareUrl";
import { useI18n } from "@/shared/composables/useI18n";
import type { Model } from "@/services/fyApi";

type Props = {
  models: Model[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const shareUrl = useCompareShareUrl("models", () =>
  props.models.map((model) => model.slug),
);

const shareTitle = computed(() => t("headlines.compare.ships"));

const erkulUrl = "https://www.erkul.games/calculator";

const spviewerUrl = computed(
  () =>
    `https://www.spviewer.eu/compare?ship=${props.models
      .map((model) => model.scIdentifier)
      .join("&ship=")}`,
);
</script>

<template>
  <div class="compare-actions">
    <Btn
      :href="erkulUrl"
      :aria-label="t('labels.hardpoints.erkul')"
      :size="BtnSizesEnum.MD"
      :variant="BtnVariantsEnum.BARE"
      mobile-icon-only
      class="erkul-link"
    >
      <i />
      {{ t("labels.hardpoints.erkul") }}
    </Btn>
    <Btn
      v-tooltip="t('labels.hardpoints.spviewerTitle')"
      :href="spviewerUrl"
      :aria-label="t('labels.hardpoints.spviewer')"
      :size="BtnSizesEnum.MD"
      :variant="BtnVariantsEnum.BARE"
      mobile-icon-only
      class="spviewer-link"
    >
      <i />
      {{ t("labels.hardpoints.spviewer") }}
    </Btn>
    <ShareBtn
      v-if="models.length"
      :url="shareUrl"
      :title="shareTitle"
      :size="BtnSizesEnum.MD"
      :variant="BtnVariantsEnum.BARE"
      no-label
    />
  </div>
</template>

<style lang="scss" scoped>
.compare-actions {
  display: flex;
  align-items: center;
  justify-content: flex-end;
  gap: 4px;
}
</style>
