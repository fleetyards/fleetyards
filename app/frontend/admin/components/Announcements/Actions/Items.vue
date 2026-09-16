<script lang="ts">
export default {
  name: "AnnouncementActionItems",
};
</script>

<script lang="ts" setup>
import {
  type Announcement,
  getAnnouncementQueryKey,
  getAnnouncementsQueryKey,
  useDestroyAnnouncement,
  usePublishAnnouncement,
} from "@/services/fyAdminApi";
import { BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  announcement: Announcement;
  withLabels?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  withLabels: false,
});

const { t } = useI18n();
const { displayConfirm, displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const invalidate = () =>
  Promise.all([
    queryClient.invalidateQueries({ queryKey: getAnnouncementsQueryKey() }),
    queryClient.invalidateQueries({
      queryKey: getAnnouncementQueryKey(props.announcement.id),
    }),
  ]);

const publishMutation = usePublishAnnouncement({
  mutation: { onSettled: invalidate },
});

const destroyMutation = useDestroyAnnouncement({
  mutation: { onSettled: invalidate },
});

const publish = () => {
  displayConfirm({
    text: t("messages.confirm.announcement.publish", {
      channels: channelSummary.value,
    }),
    onConfirm: async () => {
      await publishMutation
        .mutateAsync({ id: props.announcement.id })
        .then(() => {
          displaySuccess({ text: t("messages.announcement.published") });
        })
        .catch(() => {
          displayAlert({ text: t("messages.announcement.publishFailed") });
        });
    },
  });
};

const destroy = () => {
  displayConfirm({
    text: t("messages.confirm.announcement.destroy"),
    onConfirm: async () => {
      await destroyMutation.mutateAsync({ id: props.announcement.id });
      displaySuccess({ text: t("messages.announcement.destroyed") });
    },
  });
};
</script>

<template>
  <Btn
    v-if="props.announcement.publishable"
    v-tooltip="!withLabels && t('actions.announcements.publish')"
    data-test="announcement-publish"
    @click="publish"
  >
    <i class="fa-duotone fa-paper-plane" />
    <span v-if="withLabels">{{ t("actions.announcements.publish") }}</span>
  </Btn>
  <Btn
    v-if="props.announcement.publishable"
    v-tooltip="!withLabels && t('actions.edit')"
    :to="{
      name: 'admin-announcement-edit',
      params: { id: props.announcement.id },
    }"
  >
    <i class="fa-duotone fa-pen-to-square" />
    <span v-if="withLabels">{{ t("actions.edit") }}</span>
  </Btn>
  <Btn
    v-tooltip="!withLabels && t('actions.delete')"
    :tone="BtnTonesEnum.DANGER"
    @click="destroy"
  >
    <i class="fa-duotone fa-trash" />
    <span v-if="withLabels">{{ t("actions.delete") }}</span>
  </Btn>
</template>
