<script lang="ts">
export default {
  name: "FeatureHistory",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useAdminFeatureHistory } from "@/services/fyAdminApi";

const props = defineProps<{
  name: string;
}>();

const { t, l } = useI18n();

// Fetched per feature rather than with the list: the list renders every flag in
// the registry, and only the expanded one is ever read.
const { data: changes, isLoading } = useAdminFeatureHistory(() => props.name);

const stateVariant = (state: string): `${PillVariantsEnum}` => {
  switch (state) {
    case "on":
      return PillVariantsEnum.SUCCESS;
    case "off":
      return PillVariantsEnum.DANGER;
    default:
      return PillVariantsEnum.WARNING;
  }
};

// The gate is what actually changed; the operation alone reads the same for a
// flag opened to everyone and one granted to a single person.
const describe = (change: { operation: string; gateName?: string | null }) =>
  [change.operation, change.gateName].filter(Boolean).join(" ");
</script>

<template>
  <div class="feature-history" data-test="feature-history">
    <p v-if="isLoading" class="text-muted">
      {{ t("labels.loading") }}
    </p>

    <p
      v-else-if="!changes?.length"
      class="text-muted"
      data-test="feature-history-empty"
    >
      {{ t("labels.features.historyEmpty") }}
    </p>

    <ul v-else class="feature-history-list">
      <li
        v-for="change in changes"
        :key="change.id"
        class="feature-history-row"
        data-test="feature-history-row"
      >
        <span class="feature-history-time">{{ l(change.createdAt) }}</span>

        <BasePill :variant="stateVariant(change.stateAfter)" uppercase>
          {{ change.stateAfter }}
        </BasePill>

        <span class="feature-history-change">{{ describe(change) }}</span>
        <span v-if="change.thing" class="feature-history-thing">{{
          change.thing
        }}</span>

        <span class="feature-history-actor text-muted">
          {{ t(`labels.features.sources.${change.source}`) }}
          <template v-if="change.actor">
            {{ t("labels.features.historyBy", { actor: change.actor }) }}
          </template>
        </span>
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.feature-history-list {
  list-style: none;
  margin: 0;
  padding: 0;
}

.feature-history-row {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 0.5rem;
  padding: 0.25rem 0;
}

.feature-history-time {
  min-width: 11rem;
}

.feature-history-thing {
  font-family: monospace;
  word-break: break-all;
}

.feature-history-actor {
  margin-left: auto;
}
</style>
