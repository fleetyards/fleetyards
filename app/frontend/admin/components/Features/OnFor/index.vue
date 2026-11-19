<script lang="ts">
export default {
  name: "FeatureOnFor",
};
</script>

<script lang="ts" setup>
import { type Feature } from "@/services/fyAdminApi";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatureState } from "@/admin/composables/useFeatureState";

type Props = {
  feature: Feature;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { summaryParts } = useFeatureState();

const parts = computed(() => summaryParts(props.feature));
</script>

<template>
  <section
    class="feature-on-for"
    :aria-label="t('labels.features.onFor')"
    data-test="feature-on-for"
  >
    <span class="feature-on-for__label">{{ t("labels.features.onFor") }}</span>
    <BasePill
      v-for="part in parts"
      :key="part.key"
      :variant="PillVariantsEnum.NEUTRAL"
      :data-test="`feature-on-for-${part.key}`"
    >
      <i :class="part.icon" aria-hidden="true" />
      {{ part.label }}
    </BasePill>
    <span v-if="!parts.length" class="feature-on-for__nobody">
      {{ t("labels.features.nobody") }}
    </span>
  </section>
</template>

<style lang="scss" scoped>
.feature-on-for {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.625rem 0.75rem;
  padding: 1rem 1.25rem;
  background: var(--color-surface);
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
}

.feature-on-for__label {
  margin-right: 0.25rem;
  font-family: "Orbitron", sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.feature-on-for__nobody {
  color: var(--color-text-dim);
}
</style>
