<script lang="ts">
export default {
  name: "SupporterContributionsStats",
};
</script>

<script lang="ts" setup>
import {
  useSupporterContributionsStats,
  type SupporterContributionsStatsParams,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useCurrencyFormat } from "@/shared/composables/useCurrencyFormat";
import type { MaybeRef } from "vue";

type Props = {
  params?: MaybeRef<SupporterContributionsStatsParams>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { formatCents } = useCurrencyFormat();

const queryParams = computed(
  () => unref(props.params) as SupporterContributionsStatsParams,
);

const { data: stats } = useSupporterContributionsStats(queryParams);
</script>

<template>
  <div v-if="stats" class="supporter-contributions-stats">
    <div class="supporter-contributions-stats__entry">
      <span class="supporter-contributions-stats__label">
        {{ t("labels.supporterContribution.stats.total") }}
      </span>
      <span class="supporter-contributions-stats__value">
        {{ formatCents(stats.totalAmountCents, stats.currency) }}
      </span>
    </div>
    <div class="supporter-contributions-stats__entry">
      <span class="supporter-contributions-stats__label">
        {{ t("labels.supporterContribution.stats.count") }}
      </span>
      <span class="supporter-contributions-stats__value">{{
        stats.totalCount
      }}</span>
    </div>
    <div class="supporter-contributions-stats__entry">
      <span class="supporter-contributions-stats__label">
        {{ t("labels.supporterContribution.stats.recurringCount") }}
      </span>
      <span class="supporter-contributions-stats__value">{{
        stats.recurringCount
      }}</span>
    </div>
    <div class="supporter-contributions-stats__entry">
      <span class="supporter-contributions-stats__label">
        {{ t("labels.supporterContribution.stats.anonymousCount") }}
      </span>
      <span class="supporter-contributions-stats__value">{{
        stats.anonymousCount
      }}</span>
    </div>
  </div>
</template>

<style lang="scss" scoped>
.supporter-contributions-stats {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(140px, 1fr));
  gap: 12px;
  padding: 12px 16px;
  margin-bottom: 12px;
  background-color: rgba(255, 255, 255, 0.04);
  border-radius: 4px;

  &__entry {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  &__label {
    font-size: 0.85rem;
    opacity: 0.7;
  }

  &__value {
    font-size: 1.2rem;
    font-weight: 600;
  }
}
</style>
