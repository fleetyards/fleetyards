<script lang="ts">
export default {
  name: "CompareModelsActions",
};
</script>

<script lang="ts" setup>
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
</script>

<template>
  <div class="compare-actions">
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
  align-items: center;
  justify-content: flex-end;
}
</style>
