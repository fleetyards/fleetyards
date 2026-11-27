<script lang="ts">
export default {
  name: "AdminFeedbackShowPage",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import FeedbackConversation, {
  type ConversationEntry,
} from "@/shared/components/FeedbackConversation/index.vue";
import FeedbackReplyForm from "@/shared/components/FeedbackReplyForm/index.vue";
import FeedbackActions from "@/admin/components/Feedback/Actions/index.vue";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { ApiError } from "@/shared/types/api-error";
import { useSubscription } from "@/shared/composables/useSubscription";
import {
  AdminFeedbackChannel,
  type AdminFeedbackData,
} from "@/services/fyCableAdmin/channels/AdminFeedbackChannel";
import {
  FeedbackStateEnum,
  getFeedbackQueryKey,
  getFeedbacksQueryKey,
  useFeedback,
  useReplyToFeedback,
} from "@/services/fyAdminApi";
import { FeedbackLimits } from "@/services/fyApi";

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const route = useRoute();

const id = computed(() => String(route.params.id));

const { data: feedback, isLoading } = useFeedback(id);

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "admin-feedback" },
    label: t("headlines.admin.feedback.index"),
  },
]);

const entries = computed<ConversationEntry[]>(() => {
  if (!feedback.value) return [];

  const username = feedback.value.username || "-";

  return [
    {
      id: feedback.value.id,
      body: feedback.value.message,
      fromAdmin: false,
      author: username,
      createdAt: feedback.value.createdAt,
    },
    ...(feedback.value.replies ?? []).map((reply) => ({
      ...reply,
      author: reply.fromAdmin
        ? reply.adminName || t("feedback.mine.fleetyards")
        : username,
    })),
  ];
});

const replyMutation = useReplyToFeedback();

const send = async (body: string) => {
  await replyMutation
    .mutateAsync({ id: id.value, data: { body } })
    .then((updated) => {
      queryClient.setQueryData(getFeedbackQueryKey(id), updated);
      void queryClient.invalidateQueries({ queryKey: getFeedbacksQueryKey() });
      displaySuccess({ text: t("feedback.mine.replySent") });
    })
    .catch((error: ApiError) => {
      displayAlert({
        text: error.response?.data?.message || t("feedback.mine.replyFailed"),
      });
      throw error;
    });
};

// Replies from the other side arrive while the page is open. Nothing is
// replayed after a dropped socket, so a reconnect fetches the conversation.
useSubscription({
  channel: AdminFeedbackChannel,
  received: (data: AdminFeedbackData) => {
    if (data.id !== id.value) return;

    queryClient.setQueryData(getFeedbackQueryKey(id), data);
    void queryClient.invalidateQueries({ queryKey: getFeedbacksQueryKey() });
  },
  connected: ({ reconnect }) => {
    if (reconnect) {
      void queryClient.invalidateQueries({ queryKey: getFeedbackQueryKey(id) });
    }
  },
});
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("feedback.admin.conversation") }}</Heading>

  <Loader v-if="isLoading" :loading="isLoading" relative />

  <div v-else-if="feedback" class="admin-feedback-show">
    <div class="admin-feedback-show__meta">
      <Pill
        :variant="
          feedback.state === FeedbackStateEnum.RESOLVED
            ? PillVariantsEnum.SUCCESS
            : PillVariantsEnum.WARNING
        "
        uppercase
      >
        {{ t(`feedback.states.${feedback.state}`) }}
      </Pill>
      <span>
        {{
          feedback.featureName
            ? featureLabel(feedback.featureName)
            : t("feedback.admin.general")
        }}
      </span>
      <span v-if="feedback.pagePath" class="admin-feedback-show__path">
        {{ feedback.pagePath }}
      </span>
      <FeedbackActions :feedback="feedback" />
    </div>

    <FeedbackConversation :entries="entries" />

    <FeedbackReplyForm
      :label="t('feedback.admin.replyLabel')"
      :submit-label="t('feedback.admin.reply')"
      :hint="t('feedback.admin.replyHint')"
      :maxlength="FeedbackLimits.MESSAGE_MAX_LENGTH"
      :send="send"
    />
  </div>

  <Empty v-else variant="box" hide-actions />
</template>

<style lang="scss" scoped>
.admin-feedback-show {
  display: flex;
  flex-direction: column;
  gap: 24px;
  max-width: 800px;
}

.admin-feedback-show__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  color: var(--color-text-dim);
}

.admin-feedback-show__path {
  min-width: 0;
  overflow-wrap: anywhere;
}

@media (max-width: $desktop-breakpoint) {
  .admin-feedback-show__meta > :last-child {
    margin-left: auto;
  }

  .admin-feedback-show__path {
    flex-basis: 100%;
    order: 1;
  }
}
</style>
