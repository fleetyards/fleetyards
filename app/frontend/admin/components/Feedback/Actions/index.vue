<script lang="ts">
export default {
  name: "AdminFeedbackActions",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import type { ApiError } from "@/shared/types/api-error";
import {
  type Feedback,
  FeedbackStateEnum,
  getFeedbackQueryKey,
  getFeedbacksQueryKey,
  useReopenFeedback,
  useResolveFeedback,
} from "@/services/fyAdminApi";

type Props = {
  feedback: Feedback;
};

const props = defineProps<Props>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

const resolveMutation = useResolveFeedback();
const reopenMutation = useReopenFeedback();

const resolved = computed(
  () => props.feedback.state === FeedbackStateEnum.RESOLVED,
);

const label = computed(() =>
  resolved.value ? t("feedback.admin.reopen") : t("feedback.admin.resolve"),
);

const pending = computed(
  () => resolveMutation.isPending.value || reopenMutation.isPending.value,
);

const toggle = async () => {
  const mutation = resolved.value ? reopenMutation : resolveMutation;

  await mutation
    .mutateAsync({ id: props.feedback.id })
    .then((updated) => {
      queryClient.setQueryData(getFeedbackQueryKey(props.feedback.id), updated);
      void queryClient.invalidateQueries({ queryKey: getFeedbacksQueryKey() });
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    });
};
</script>

<template>
  <Btn
    v-tooltip="label"
    :aria-label="label"
    :loading="pending"
    :data-test="`feedback-${resolved ? 'reopen' : 'resolve'}`"
    @click="toggle"
  >
    <i
      :class="
        resolved ? 'fa-duotone fa-arrow-rotate-left' : 'fa-duotone fa-check'
      "
    />
  </Btn>
</template>
