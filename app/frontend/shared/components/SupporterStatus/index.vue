<script lang="ts">
export default {
  name: "SupporterStatus",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import SupporterBadge from "@/shared/components/SupporterBadge/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { differenceInCalendarDays, parseISO } from "date-fns";

// Spelled out as primitives rather than taking a user: the admin API and the
// public one generate two unrelated User types for the same fields, and this
// renders the same thing for both.
interface Props {
  supporter?: boolean;
  supporterTier?: number;
  supporterRecurring?: boolean;
  // Absent while support does not lapse on a nameable date -- an open-ended
  // recurring pledge covers it, and only ending that would set one.
  supporterUntil?: string;
  // Admin only. The day the fleet tier this contribution funds would run out --
  // a projection for an admin to act on, and a different question from whether
  // support is live, which is what the donor is shown.
  fleetTierUntil?: string;
  // A standing pledge covering the monthly rate funds it for as long as it
  // stands, so there is no day to name and none to go past.
  fleetTierOngoing?: boolean;
}

const props = defineProps<Props>();

const { t, l } = useI18n();

const EXPIRING_WITHIN_DAYS = 14;

const fleetTier = computed(() =>
  props.supporter ? props.fleetTierUntil : undefined,
);

const fleetTierOngoing = computed(
  () => Boolean(props.supporter) && Boolean(props.fleetTierOngoing),
);

// Whatever the reader can actually see. The tint has to answer for a date on the
// screen, and where the fleet tier is shown it is that date -- tinting for a
// hidden `supporterUntil` puts an "expiring soon" amber next to a date months
// away.
const runsOutOn = computed(() =>
  fleetTierOngoing.value
    ? undefined
    : (fleetTier.value ?? props.supporterUntil),
);

// The fleet tier is a fixed date bought outright, so it can simply be behind
// us -- an ended pledge that paid for eight months ran out on a day that has
// been and gone. Saying so is all the admin needs; acting on it is the fleet
// work's job.
const fleetTierExpired = computed(() => {
  if (!fleetTier.value) {
    return false;
  }

  return differenceInCalendarDays(parseISO(fleetTier.value), new Date()) < 0;
});

const expiringSoon = computed(() => {
  if (!runsOutOn.value) {
    return false;
  }

  const days = differenceInCalendarDays(parseISO(runsOutOn.value), new Date());

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

// Yields to the fleet tier wherever that is shown: one is the calendar month's
// edge and the other a spend-down of the same money, so the two give different
// dates and the pair reads as a contradiction rather than as detail.
const expiry = computed(() => {
  if (!props.supporter || fleetTier.value || fleetTierOngoing.value) {
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
      <SupporterBadge
        v-if="
          props.supporter && (props.supporterTier || props.supporterRecurring)
        "
        :tier="props.supporterTier"
        :recurring="props.supporterRecurring"
        :size="16"
      />
      <i
        v-else
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
    <span
      v-if="fleetTierOngoing"
      class="supporter-status__fleet-tier"
      data-test="fleet-tier-ongoing"
    >
      {{ t("labels.supporter.fleetTierOngoing") }}
    </span>
    <span
      v-else-if="fleetTier"
      class="supporter-status__fleet-tier"
      data-test="fleet-tier-until"
    >
      {{
        t("labels.supporter.fleetTierUntil", {
          date: l(fleetTier, "datetime.formats.date"),
        })
      }}
      <Pill
        v-if="fleetTierExpired"
        :variant="PillVariantsEnum.DANGER"
        data-test="fleet-tier-expired"
      >
        {{ t("labels.supporter.fleetTierExpired") }}
      </Pill>
    </span>
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

.supporter-status__fleet-tier {
  display: inline-flex;
  align-items: center;
  gap: 0.5rem;
  color: var(--color-muted, #7a8288);
}
</style>
