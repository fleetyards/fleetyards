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
  useSendAnnouncementTest,
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
const route = useRoute();
const router = useRouter();
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

// The list only: the detail query would refetch a record that is gone. A
// detail page watching it leaves first, and drops the entry after.
const destroyMutation = useDestroyAnnouncement({
  mutation: {
    onSettled: () =>
      queryClient.invalidateQueries({ queryKey: getAnnouncementsQueryKey() }),
  },
});

const sendTestMutation = useSendAnnouncementTest({
  mutation: { onSettled: invalidate },
});

// No confirm: the dry run goes to the admin Discord channel and nowhere a
// reader can see, which is the whole reason it exists.
const sendTest = async () => {
  await sendTestMutation
    .mutateAsync({ id: props.announcement.id })
    .then(() => {
      displaySuccess({ text: t("messages.announcement.testSent") });
    })
    .catch(() => {
      displayAlert({ text: t("messages.announcement.testFailed") });
    });
};

/*
 * An announcement cannot be recalled once it is out, so the confirm names the
 * channels it is about to reach rather than asking "are you sure?" about an
 * unnamed action.
 */
const channelSummary = computed(() =>
  [
    props.announcement.notifyUsers &&
      t("labels.admin.announcements.channels.in_app"),
    props.announcement.postDiscord &&
      t("labels.admin.announcements.channels.discord"),
    props.announcement.postBluesky &&
      t("labels.admin.announcements.channels.bluesky"),
    props.announcement.postX && t("labels.admin.announcements.channels.x"),
  ]
    .filter(Boolean)
    .join(", "),
);

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
      await destroyMutation
        .mutateAsync({ id: props.announcement.id })
        .then(async () => {
          displaySuccess({ text: t("messages.announcement.destroyed") });

          if (route.name === "admin-announcement") {
            await router.push({ name: "admin-announcements" });
          }

          queryClient.removeQueries({
            queryKey: getAnnouncementQueryKey(props.announcement.id),
            exact: true,
          });
        })
        .catch(() => {
          displayAlert({ text: t("messages.announcement.destroyFailed") });
        });
    },
  });
};
</script>

<template>
  <Btn
    v-tooltip="!withLabels && t('actions.announcements.sendTest')"
    data-test="announcement-send-test"
    @click="sendTest"
  >
    <i class="fa-duotone fa-flask" />
    <span v-if="withLabels">{{ t("actions.announcements.sendTest") }}</span>
  </Btn>
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
