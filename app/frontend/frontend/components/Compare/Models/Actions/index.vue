<script lang="ts">
export default {
  name: "CompareModelsActions",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
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

const scIdentifiers = computed(() =>
  props.models.map((model) => model.scIdentifier),
);

const spviewerUrl = computed(
  () =>
    `https://www.spviewer.eu/compare?ship=${scIdentifiers.value.join("&ship=")}`,
);
</script>

<template>
  <!-- Deliberately not `.page-actions`: that class carries `margin-bottom: 20px` to
       separate an action row from the content below it, which in a header row makes this
       box taller than the picker beside it and knocks the two out of alignment. -->
  <div class="compare-actions">
    <Btn
      :href="erkulUrl"
      :aria-label="t('labels.hardpoints.erkul')"
      :size="BtnSizesEnum.MD"
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
      no-label
    />
  </div>
</template>

<style lang="scss" scoped>
.compare-actions {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  justify-content: flex-end;
  gap: 10px;
}
</style>
