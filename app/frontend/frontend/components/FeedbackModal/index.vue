<script lang="ts">
export default {
  name: "FeedbackModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { featureLabel } from "@/shared/utils/BetaFeatures";
import {
  FeedbackLimits,
  type FeatureFlagName,
  useBetaFeatures as useBetaFeaturesQuery,
  useCreateFeedback as useCreateFeedbackMutation,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  feature?: FeatureFlagName;
  pagePath?: string;
};

const props = withDefaults(defineProps<Props>(), {
  feature: undefined,
  pagePath: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const { data: betaFeatures } = useBetaFeaturesQuery({
  query: { staleTime: 5 * 60 * 1000, retry: false },
});

const featureOptions = computed(() =>
  [...new Set([...(betaFeatures.value ?? []), props.feature ?? []].flat())]
    .sort()
    .map((feature) => ({ value: feature, label: featureLabel(feature) })),
);

const initialValues = {
  feature: props.feature ?? null,
  message: "",
};

const { defineField, handleSubmit, values } = useForm({ initialValues });

// Read by AppModal, which asks before a close would throw typed input away.
defineExpose({ dirty: useFormDirty(values, { ...initialValues }) });

const [feature] = defineField("feature");
const [message, messageProps] = defineField("message");

const mutation = useCreateFeedbackMutation();

const onSubmit = handleSubmit(async (values) => {
  await mutation
    .mutateAsync({
      data: {
        message: String(values.message).trim(),
        featureName: values.feature || null,
        pagePath: props.pagePath ?? null,
      },
    })
    .then(() => {
      displaySuccess({ text: t("feedback.sent") });
      comlink.emit("close-modal", true);
    })
    .catch((error: ApiError) => {
      displayAlert({
        text: error.response?.data?.message || t("feedback.failed"),
      });
    });
});
</script>

<template>
  <Modal :title="t('feedback.title')">
    <form
      id="feedback-form"
      data-test="feedback-form"
      @submit.prevent="onSubmit"
    >
      <p class="feedback-form__intro">{{ t("feedback.intro") }}</p>
      <BaseSelect
        v-model="feature"
        name="feature"
        :options="featureOptions"
        :label="t('feedback.feature')"
        data-test="feedback-feature"
      />
      <FormTextarea
        v-model="message"
        name="message"
        v-bind="messageProps"
        rules="required"
        :label="t('feedback.message')"
        :maxlength="FeedbackLimits.MESSAGE_MAX_LENGTH"
        autofocus
        data-test="feedback-message"
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="feedback-form"
        :loading="mutation.isPending.value"
        commit
        data-test="feedback-submit"
      >
        {{ t("feedback.send") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.feedback-form__intro {
  margin: 0 0 16px;
  color: var(--color-text-dim, #959595);
}
</style>
