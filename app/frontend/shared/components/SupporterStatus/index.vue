<script lang="ts">
export default {
  name: "SupporterStatus",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { differenceInCalendarDays, parseISO } from "date-fns";

export interface SupporterTierProjection {
  tier: number;
  expiresAt: string;
}

// Spelled out as primitives rather than taking a user: the admin API and the
// public one generate two unrelated User types for the same fields, and this
// renders the same thing for both.
interface Props {
  supporter?: boolean;
  // Absent while support does not lapse on a nameable date -- an open-ended
  // recurring pledge covers it, and only ending that would set one.
  supporterUntil?: string;
  // Admin only. How long what is already paid would sustain each tier, which is
  // a projection for an admin to act on rather than something to put in front of
  // the person it describes -- a supporter is shown that they are one, and the
  // tier they end up holding is theirs to choose.
  tierProjections?: SupporterTierProjection[];
}

const props = defineProps<Props>();

const { t, l } = useI18n();

const EXPIRING_WITHIN_DAYS = 14;

const expiringSoon = computed(() => {
  if (!props.supporterUntil) {
    return false;
  }

  const days = differenceInCalendarDays(
    parseISO(props.supporterUntil),
    new Date(),
  );

  return days <= EXPIRING_WITHIN_DAYS;
});

const variant = computed(() => {
  if (!props.supporter) {
    return PillVariantsEnum.NEUTRAL;
  }

  return expiringSoon.value
    ? PillVariantsEnum.WARNING
    : PillVariantsEnum.SUCCESS;
});

const projections = computed(() =>
  props.supporter ? (props.tierProjections ?? []) : [],
);

const expiry = computed(() => {
  if (!props.supporter) {
    return undefined;
  }

  if (!props.supporterUntil) {
    return t("labels.supporter.ongoing");
  }

  const date = l(props.supporterUntil, "datetime.formats.date");

  return expiringSoon.value
    ? t("labels.supporter.expiring", { date })
    : t("labels.supporter.until", { date });
});
</script>

<template>
  <div class="supporter-status" data-test="supporter-status">
    <Pill :variant="variant" data-test="supporter-status-pill">
      <i
        :class="props.supporter ? 'fa-duotone fa-heart' : 'fa-light fa-heart'"
      />
      {{
        props.supporter
          ? t("labels.supporter.badge")
          : t("labels.supporter.none")
      }}
    </Pill>
    <span v-if="expiry" class="supporter-status__expiry">
      {{ expiry }}
    </span>
    <ul v-if="projections.length" class="supporter-status__tiers">
      <li
        v-for="projection in projections"
        :key="projection.tier"
        data-test="supporter-tier-projection"
      >
        {{
          t("labels.supporter.tierUntil", {
            tier: projection.tier,
            date: l(projection.expiresAt, "datetime.formats.date"),
          })
        }}
      </li>
    </ul>
  </div>
</template>

<style lang="scss" scoped>
.supporter-status {
  display: flex;
  align-items: center;
  gap: 0.75rem;
  flex-wrap: wrap;
  margin-bottom: 1rem;
}

.supporter-status__expiry {
  color: var(--color-muted, #7a8288);
}

/* Basis of its own so the tier lines wrap under the badge rather than stretching
   the row, which they do as soon as two of them sit beside a long expiry. */
.supporter-status__tiers {
  flex-basis: 100%;
  margin: 0;
  padding: 0;
  list-style: none;
  color: var(--color-muted, #7a8288);
}
</style>
