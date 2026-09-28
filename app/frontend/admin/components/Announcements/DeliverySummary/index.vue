<script lang="ts">
export default {
  name: "AnnouncementDeliverySummary",
};
</script>

<script lang="ts" setup>
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  type AnnouncementDelivery,
  AnnouncementDeliveryStatusEnum,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";

interface Props {
  deliveries: AnnouncementDelivery[];
}

const props = defineProps<Props>();

const { t } = useI18n();

const count = (status: AnnouncementDeliveryStatusEnum) =>
  props.deliveries.filter((delivery) => delivery.status === status).length;

const sent = computed(() => count(AnnouncementDeliveryStatusEnum.SUCCEEDED));
const failed = computed(() => count(AnnouncementDeliveryStatusEnum.FAILED));
const pending = computed(() => count(AnnouncementDeliveryStatusEnum.PENDING));
const skipped = computed(() => count(AnnouncementDeliveryStatusEnum.SKIPPED));

// A failure is the one thing on the list worth stopping for, so it outranks a
// send still in flight.
const variant = computed(() => {
  if (failed.value) return PillVariantsEnum.DANGER;
  if (pending.value) return PillVariantsEnum.DEFAULT;
  if (sent.value === props.deliveries.length) return PillVariantsEnum.SUCCESS;

  return PillVariantsEnum.WARNING;
});

const label = computed(() =>
  [
    t("labels.admin.announcements.deliverySummary", {
      sent: sent.value,
      total: props.deliveries.length,
    }),
    failed.value &&
      t("labels.admin.announcements.deliveryFailedCount", {
        count: failed.value,
      }),
    pending.value &&
      t("labels.admin.announcements.deliveryPendingCount", {
        count: pending.value,
      }),
    skipped.value &&
      t("labels.admin.announcements.deliverySkippedCount", {
        count: skipped.value,
      }),
  ]
    .filter(Boolean)
    .join(" · "),
);
</script>

<template>
  <Pill :variant="variant" data-test="announcement-delivery-summary">
    {{ label }}
  </Pill>
</template>
