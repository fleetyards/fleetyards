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

// Spelled out as primitives rather than taking a user: the admin API and the
// public one generate two unrelated User types for the same three fields, and
// this renders the same thing for both.
interface Props {
  supporter?: boolean;
  supporterTier?: number;
  // Absent while support does not lapse on a nameable date -- an open-ended
  // recurring pledge covers it, and only ending that would set one.
  supporterUntil?: string;
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

// A tier of 0 is what everybody who is not a supporter has, so it says nothing
// worth a line of its own.
const tier = computed(() =>
  props.supporter && props.supporterTier ? props.supporterTier : undefined,
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
      <template v-if="tier">
        · {{ t("labels.supporter.tier", { tier }) }}
      </template>
    </Pill>
    <span v-if="expiry" class="supporter-status__expiry">
      {{ expiry }}
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
</style>
