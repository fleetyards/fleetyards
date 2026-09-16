<script lang="ts">
export default {
  name: "SupporterNomination",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useSessionStore } from "@/frontend/stores/session";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  getMySupporterContributionsQueryKey,
  useMyFleets,
  useMySupporterContributions,
  useNominateFleetForSupporterContribution,
  FeatureFlagName,
  type FilterOption,
  type MySupporterContribution,
} from "@/services/fyApi";

const { t, l } = useI18n();
const sessionStore = useSessionStore();
const queryClient = useQueryClient();
const { displaySuccess, displayAlert } = useAppNotifications();

const { isFeatureEnabled } = useFeatures();

// Rollout, not entitlement: while the flag is off the whole surface is absent
// and the endpoints behind it answer `forbidden`, so the premium work can sit
// in production until the transition is announced.
const enabled = computed(
  () =>
    sessionStore.isAuthenticated &&
    isFeatureEnabled(FeatureFlagName.FLEET_SUBSCRIPTIONS),
);

// Only contributions already linked to this account come back, so a visitor
// who has never donated -- or whose donation has not been matched yet -- sees
// nothing here at all rather than an empty form asking them to pick a fleet.
const { data: contributions } = useMySupporterContributions({
  query: { enabled },
});

// `myFleets` is accepted-only on the server, which is the same rule the
// nomination is validated against. So nothing offered here can be refused.
const { data: fleets } = useMyFleets({ query: { enabled } });

const { mutateAsync: nominate } = useNominateFleetForSupporterContribution();

const rows = computed<MySupporterContribution[]>(() =>
  enabled.value ? (contributions.value ?? []) : [],
);

const fleetOptions = computed<FilterOption[]>(() =>
  (fleets.value ?? []).map((fleet) => ({
    label: fleet.name,
    value: fleet.id,
  })),
);

const formatAmount = (contribution: MySupporterContribution) =>
  new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: contribution.currency,
  }).format(contribution.amountCents / 100);

const onSelect = async (
  contribution: MySupporterContribution,
  fleetId: string | null,
) => {
  try {
    await nominate({ id: contribution.id, data: { fleetId } });

    void queryClient.invalidateQueries({
      queryKey: getMySupporterContributionsQueryKey(),
    });

    displaySuccess({
      text: t("messages.supporterNomination.update.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.supporterNomination.update.failure"),
    });
  }
};
</script>

<template>
  <div v-if="rows.length" class="supporter-nomination" data-test="nomination">
    <div class="supporter-nomination__label">
      {{ t("labels.account.supporterNomination.label") }}
    </div>

    <p class="supporter-nomination__hint">
      {{ t("labels.account.supporterNomination.hint") }}
    </p>

    <div
      v-for="contribution in rows"
      :key="contribution.id"
      class="supporter-nomination__row"
      :data-test="`nomination-${contribution.id}`"
    >
      <div class="supporter-nomination__contribution">
        <span class="supporter-nomination__amount">
          {{ formatAmount(contribution) }}
        </span>
        <span class="supporter-nomination__date">
          {{ l(contribution.startedAt, "datetime.formats.short") }}
        </span>
      </div>

      <BaseSelect
        :name="`nomination-${contribution.id}`"
        :model-value="contribution.fleet?.id ?? null"
        :options="fleetOptions"
        :label="t('labels.account.supporterNomination.fleet')"
        nullable
        no-label
        @update:model-value="
          (value) => onSelect(contribution, (value as string) || null)
        "
      />
    </div>
  </div>
</template>

<style lang="scss" scoped>
.supporter-nomination {
  margin-top: 1.5rem;
}

.supporter-nomination__label {
  font-weight: 600;
}

.supporter-nomination__hint {
  margin-bottom: 1rem;
  font-size: 0.85rem;
  opacity: 0.75;
}

.supporter-nomination__row {
  display: flex;
  flex-wrap: wrap;
  gap: 0.75rem;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.75rem;
}

.supporter-nomination__contribution {
  display: flex;
  gap: 0.5rem;
  align-items: baseline;
}

.supporter-nomination__date {
  font-size: 0.85rem;
  opacity: 0.75;
}
</style>
