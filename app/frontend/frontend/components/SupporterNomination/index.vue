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
import { AppConfirmTonesEnum } from "@/shared/components/AppConfirm/types";
import {
  getMySupporterContributionsQueryKey,
  getMySupportedFleetQueryKey,
  useMyFleets,
  useMySupporterContributions,
  useMySupportedFleet,
  useChooseMySupportedFleet,
  useNominateFleetForSupporterContribution,
  FeatureFlagName,
  type FilterOption,
  type MySupporterContribution,
} from "@/services/fyApi";

const { t, l } = useI18n();
const sessionStore = useSessionStore();
const queryClient = useQueryClient();
const { displaySuccess, displayAlert, displayConfirm } = useAppNotifications();

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

// The standing choice, answerable with no donation in sight. This is the part
// somebody can act on at the moment they are deciding -- a contribution does
// not exist until a payment has been imported and matched, which is days later
// for a Patreon sync or a hand-entered payment.
const { data: supported } = useMySupportedFleet({ query: { enabled } });

const { mutateAsync: chooseSupportedFleet } = useChooseMySupportedFleet();

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

// Shown whenever there is a fleet to choose, donation or not. Without a fleet
// there is nothing to pick from, and the section would be a dead control.
const hasFleets = computed(
  () => enabled.value && fleetOptions.value.length > 0,
);

const choosing = ref(false);

// BaseSelect keeps its own value and only re-syncs when `model-value` changes.
// Backing out of the confirm changes nothing, so the select would sit showing
// the fleet that was not chosen; bumping the key remounts it on the real one.
const selectKey = ref(0);

// Only when something is being taken away. Picking a first fleet, or picking
// the one already chosen, costs nobody anything and asks nothing.
const onChooseSupported = (fleetId: string | null) => {
  if (choosing.value) return;

  const current = supported.value?.fleet;

  if (!current || current.id === fleetId) {
    void applySupportedFleet(fleetId);
    return;
  }

  displayConfirm({
    text: t("messages.supporterNomination.change.confirm", {
      fleet: current.name,
    }),
    confirmText: t("actions.supporterNomination.change"),
    tone: AppConfirmTonesEnum.WARNING,
    onConfirm: () => applySupportedFleet(fleetId),
    onClose: () => {
      selectKey.value += 1;
    },
  });
};

const applySupportedFleet = async (fleetId: string | null) => {
  choosing.value = true;

  try {
    await chooseSupportedFleet({ data: { fleetId } });

    void queryClient.invalidateQueries({
      queryKey: getMySupportedFleetQueryKey(),
    });

    displaySuccess({
      text: t("messages.supporterNomination.update.success"),
    });
  } catch {
    displayAlert({
      text: t("messages.supporterNomination.update.failure"),
    });
  } finally {
    choosing.value = false;
  }
};

const formatAmount = (contribution: MySupporterContribution) =>
  new Intl.NumberFormat(undefined, {
    style: "currency",
    currency: contribution.currency,
  }).format(contribution.amountCents / 100);

// Two selections on one row can otherwise be in flight together, and the
// server applies each as it arrives with no version check -- so an earlier
// choice completing last would win. Per contribution rather than globally:
// picking for one contribution must not freeze the others.
const pending = ref<string[]>([]);

const isPending = (id: string) => pending.value.includes(id);

const rowKeys = ref<Record<string, number>>({});

const rowKey = (id: string) => rowKeys.value[id] ?? 0;

const onSelect = (
  contribution: MySupporterContribution,
  fleetId: string | null,
) => {
  if (isPending(contribution.id)) return;

  const current = contribution.fleet;

  if (!current || current.id === fleetId) {
    void applyNomination(contribution, fleetId);
    return;
  }

  displayConfirm({
    text: t("messages.supporterNomination.change.confirm", {
      fleet: current.name,
    }),
    confirmText: t("actions.supporterNomination.change"),
    tone: AppConfirmTonesEnum.WARNING,
    onConfirm: () => applyNomination(contribution, fleetId),
    onClose: () => {
      rowKeys.value = {
        ...rowKeys.value,
        [contribution.id]: rowKey(contribution.id) + 1,
      };
    },
  });
};

const applyNomination = async (
  contribution: MySupporterContribution,
  fleetId: string | null,
) => {
  pending.value = [...pending.value, contribution.id];

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
  } finally {
    pending.value = pending.value.filter((id) => id !== contribution.id);
  }
};
</script>

<template>
  <div v-if="hasFleets" class="supporter-nomination" data-test="nomination">
    <div class="supporter-nomination__label">
      {{ t("labels.account.supporterNomination.label") }}
    </div>

    <div class="row">
      <div class="col-12 col-md-6">
        <BaseSelect
          :key="selectKey"
          name="supportedFleet"
          :model-value="supported?.fleet?.id ?? null"
          :options="fleetOptions"
          :label="t('labels.account.supporterNomination.fleet')"
          :disabled="choosing"
          nullable
          no-label
          data-test="supported-fleet"
          @update:model-value="
            (value) => onChooseSupported((value as string) || null)
          "
        />

        <p class="supporter-nomination__hint">
          {{ t("labels.account.supporterNomination.hint") }}
        </p>
      </div>
    </div>

    <template v-if="rows.length">
      <div class="supporter-nomination__label supporter-nomination__label--sub">
        {{ t("labels.account.supporterNomination.perDonation") }}
      </div>

      <p class="supporter-nomination__hint">
        {{ t("labels.account.supporterNomination.perDonationHint") }}
      </p>
    </template>

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
        :key="rowKey(contribution.id)"
        :name="`nomination-${contribution.id}`"
        :model-value="contribution.fleet?.id ?? null"
        :options="fleetOptions"
        :label="t('labels.account.supporterNomination.fleet')"
        :disabled="isPending(contribution.id)"
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
  margin-top: 0.35rem;
  margin-bottom: 1.5rem;
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
