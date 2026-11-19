<script lang="ts">
export default {
  name: "SettingsFeedbackShowPage",
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
import FeedbackConversation, {
  type ConversationEntry,
} from "@/shared/components/FeedbackConversation/index.vue";
import FeedbackReplyForm from "@/shared/components/FeedbackReplyForm/index.vue";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { ApiError } from "@/shared/types/api-error";
import {
  FeedbackStateEnum,
  getFeedbackQueryKey,
  getFeedbacksQueryKey,
  useFeedback,
  useReplyToFeedback,
} from "@/services/fyApi";

const MESSAGE_MAX_LENGTH = 5000;

const { t } = useI18n();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();
const route = useRoute();

const id = computed(() => String(route.params.id));

const { data: feedback, isLoading } = useFeedback(id);

const crumbs = computed<Crumb[]>(() => [
  { to: { name: "settings-profile" }, label: t("nav.settings.index") },
  { to: { name: "settings-feedback" }, label: t("feedback.mine.back") },
]);

const entries = computed<ConversationEntry[]>(() => {
  if (!feedback.value) return [];

  const author = (fromAdmin: boolean) =>
    fromAdmin ? t("feedback.mine.fleetyards") : t("feedback.mine.you");

  return [
    {
      id: feedback.value.id,
      body: feedback.value.message,
      fromAdmin: false,
      author: author(false),
      createdAt: feedback.value.createdAt,
    },
    ...(feedback.value.replies ?? []).map((reply) => ({
      ...reply,
      author: author(reply.fromAdmin),
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
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading hero>{{ t("feedback.mine.conversation") }}</Heading>

  <Loader v-if="isLoading" :loading="isLoading" relative />

  <div v-else-if="feedback" class="feedback-show">
    <div class="feedback-show__meta">
      <Pill
        :variant="
          feedback.state === FeedbackStateEnum.RESOLVED
            ? PillVariantsEnum.SUCCESS
            : PillVariantsEnum.DEFAULT
        "
        uppercase
      >
        {{ t(`feedback.states.${feedback.state}`) }}
      </Pill>
      <span v-if="feedback.featureName">
        {{ featureLabel(feedback.featureName) }}
      </span>
      <span v-if="feedback.pagePath">{{ feedback.pagePath }}</span>
    </div>

    <FeedbackConversation :entries="entries" />

    <FeedbackReplyForm
      :label="t('feedback.mine.replyLabel')"
      :submit-label="t('feedback.mine.reply')"
      :maxlength="MESSAGE_MAX_LENGTH"
      :send="send"
    />
  </div>
</template>

<style lang="scss" scoped>
.feedback-show {
  display: flex;
  flex-direction: column;
  gap: 24px;
  max-width: 800px;
}

.feedback-show__meta {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 12px;
  color: var(--color-text-dim);
}
</style>
