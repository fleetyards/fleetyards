<script lang="ts">
export default {
  name: "FeatureHistory",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useAdminFeatureHistory } from "@/services/fyAdminApi";
import { useFeatureState } from "@/admin/composables/useFeatureState";

interface Props {
  name: string;
  // Rows shown before "show all". The API caps the history, so the rest
  // expands in place instead of paging.
  limit?: number;
}

const props = withDefaults(defineProps<Props>(), {
  limit: undefined,
});

const { t, l, timeDistance } = useI18n();
const { stateLabel } = useFeatureState();

// Fetched per feature rather than with the list: the list renders every flag in
// the registry, and only the open one is ever read.
const { data: changes, isLoading } = useAdminFeatureHistory(() => props.name);

const expanded = ref(false);

const visible = computed(() => {
  const all = changes.value ?? [];

  return props.limit && !expanded.value ? all.slice(0, props.limit) : all;
});

const hidden = computed(
  () => (changes.value?.length ?? 0) - visible.value.length,
);

// The gate is what actually changed; the operation alone reads the same for a
// flag opened to everyone and one granted to a single person.
const describe = (change: { operation: string; gateName?: string | null }) =>
  [change.operation, change.gateName].filter(Boolean).join(" ");
</script>

<template>
  <div class="feature-history" data-test="feature-history">
    <p v-if="isLoading" class="feature-history__note">
      {{ t("labels.loading") }}
    </p>

    <p
      v-else-if="!changes?.length"
      class="feature-history__note"
      data-test="feature-history-empty"
    >
      {{ t("labels.features.historyEmpty") }}
    </p>

    <template v-else>
      <ol class="feature-history__list">
        <li
          v-for="change in visible"
          :key="change.id"
          class="feature-history__row"
          data-test="feature-history-row"
        >
          <span
            class="feature-history__dot"
            :class="`feature-history__dot--${change.stateAfter}`"
            role="img"
            :aria-label="stateLabel(change.stateAfter)"
            :title="stateLabel(change.stateAfter)"
          />
          <div class="feature-history__body">
            <span class="feature-history__what">
              {{ describe(change) }}
              <span v-if="change.thing" class="feature-history__thing">{{
                change.thing
              }}</span>
            </span>
            <span class="feature-history__meta">
              <time :datetime="change.createdAt" :title="l(change.createdAt)">{{
                timeDistance(change.createdAt)
              }}</time>
              ·
              {{ t(`labels.features.sources.${change.source}`) }}
              <template v-if="change.actor">
                {{ t("labels.features.historyBy", { actor: change.actor }) }}
              </template>
            </span>
          </div>
        </li>
      </ol>

      <Btn
        v-if="hidden > 0"
        :variant="BtnVariantsEnum.BARE"
        class="feature-history__more"
        data-test="feature-history-more"
        @click="expanded = true"
      >
        {{ t("labels.features.historyShowAll", { count: hidden }) }}
      </Btn>
    </template>
  </div>
</template>

<style lang="scss" scoped>
.feature-history__note {
  margin: 0;
  color: var(--color-text-dim);
}

.feature-history__list {
  display: flex;
  flex-direction: column;
  list-style: none;
  margin: 0;
  padding: 0;
}

.feature-history__row {
  display: grid;
  grid-template-columns: 10px minmax(0, 1fr);
  gap: 0.75rem;
  padding: 0.625rem 0;
  border-bottom: 1px solid var(--color-edge-faint);

  &:first-child {
    padding-top: 0;
  }
}

.feature-history__dot {
  width: 10px;
  height: 10px;
  margin-top: 0.4rem;
  border-radius: 50%;
  background: var(--color-warning);

  &--on {
    background: var(--color-success);
  }

  &--off {
    background: var(--color-danger);
  }
}

.feature-history__body {
  display: flex;
  flex-direction: column;
  gap: 0.125rem;
  min-width: 0;
}

.feature-history__what {
  color: var(--color-lifted);
  font-size: 14px;
}

.feature-history__thing {
  font-family: monospace;
  word-break: break-all;
  color: var(--color-text);
}

.feature-history__meta {
  font-size: 13px;
  color: var(--color-text-dim);
}

.feature-history__more {
  margin-top: 0.75rem;
}
</style>
