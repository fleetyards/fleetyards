<script lang="ts">
export default {
  name: "AnnouncementDeliveries",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  type Announcement,
  type AnnouncementDelivery,
  AnnouncementDeliveryStatusEnum,
  getAnnouncementQueryKey,
  getAnnouncementsQueryKey,
  useRetryAnnouncementDelivery,
} from "@/services/fyAdminApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  announcement: Announcement;
};

const props = defineProps<Props>();

const { t, l } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const variants: Record<AnnouncementDeliveryStatusEnum, PillVariantsEnum> = {
  [AnnouncementDeliveryStatusEnum.PENDING]: PillVariantsEnum.DEFAULT,
  [AnnouncementDeliveryStatusEnum.SUCCEEDED]: PillVariantsEnum.SUCCESS,
  [AnnouncementDeliveryStatusEnum.SKIPPED]: PillVariantsEnum.NEUTRAL,
  [AnnouncementDeliveryStatusEnum.FAILED]: PillVariantsEnum.DANGER,
};

const retryable = (delivery: AnnouncementDelivery) =>
  delivery.status === AnnouncementDeliveryStatusEnum.FAILED ||
  delivery.status === AnnouncementDeliveryStatusEnum.SKIPPED;

const retryMutation = useRetryAnnouncementDelivery({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getAnnouncementsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getAnnouncementQueryKey(props.announcement.id),
        }),
      ]);
    },
  },
});

const retry = async (delivery: AnnouncementDelivery) => {
  await retryMutation
    .mutateAsync({ id: props.announcement.id, channel: delivery.channel })
    .then(() => {
      displaySuccess({ text: t("messages.announcement.retryQueued") });
    })
    .catch(() => {
      displayAlert({ text: t("messages.announcement.retryFailed") });
    });
};
</script>

<template>
  <ul class="announcement-deliveries" data-test="announcement-deliveries">
    <li
      v-for="delivery in props.announcement.deliveries"
      :key="delivery.channel"
      class="announcement-deliveries__row"
    >
      <span class="announcement-deliveries__channel">
        {{ t(`labels.admin.announcements.channels.${delivery.channel}`) }}
      </span>
      <Pill :variant="variants[delivery.status]" uppercase>
        {{
          t(`labels.admin.announcements.deliveryStatuses.${delivery.status}`)
        }}
      </Pill>
      <span v-if="delivery.deliveredAt" class="announcement-deliveries__meta">
        {{ l(delivery.deliveredAt, "datetime.formats.short") }}
      </span>
      <span v-if="delivery.error" class="announcement-deliveries__error">
        {{ delivery.error }}
      </span>
      <Btn
        v-if="retryable(delivery)"
        :size="BtnSizesEnum.SM"
        :aria-label="t('actions.announcements.retry')"
        data-test="announcement-delivery-retry"
        @click="retry(delivery)"
      >
        <i class="fa-duotone fa-rotate-right" />
        {{ t("actions.announcements.retry") }}
      </Btn>
    </li>
  </ul>
</template>

<style lang="scss" scoped>
.announcement-deliveries {
  list-style: none;
  margin: 0;
  padding: 0;
}

.announcement-deliveries__row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 8px;
  padding: 6px 0;
}

.announcement-deliveries__channel {
  min-width: 90px;
  font-weight: 600;
}

.announcement-deliveries__meta,
.announcement-deliveries__error {
  color: $gray-lighter;
  font-size: 0.875rem;
}

.announcement-deliveries__error {
  flex-basis: 100%;
}
</style>
