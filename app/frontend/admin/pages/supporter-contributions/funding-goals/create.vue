<script lang="ts">
export default {
  name: "AdminFundingGoalCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type FundingGoalInput,
  useCreateFundingGoal,
  getFundingGoalsQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { todayIsoDateLocal } from "@/shared/utils/dateHelpers";
import { toCents } from "@/shared/utils/currencyHelpers";
import { useQueryClient } from "@tanstack/vue-query";

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

type FormValues = {
  title: string;
  description?: string;
  amount?: number;
  effectiveFrom: string;
  endedAt?: string;
  currency: string;
};

const validationSchema = {
  title: "required",
  amount: "required",
  effectiveFrom: "required",
};

const initialValues = ref<FormValues>({
  title: "",
  description: undefined,
  amount: undefined,
  effectiveFrom: todayIsoDateLocal(),
  endedAt: undefined,
  currency: "EUR",
});

const { defineField, handleSubmit, meta } = useForm<FormValues>({
  initialValues: initialValues.value,
  validationSchema,
});

const [title, titleProps] = defineField("title");
const [description, descriptionProps] = defineField("description");
const [amount, amountProps] = defineField("amount");
const [effectiveFrom, effectiveFromProps] = defineField("effectiveFrom");
const [endedAt, endedAtProps] = defineField("endedAt");

const submitting = ref(false);

const createMutation = useCreateFundingGoal({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getFundingGoalsQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const payload: FundingGoalInput = {
    title: values.title,
    description: values.description || undefined,
    amountCents: toCents(values.amount),
    effectiveFrom: values.effectiveFrom,
    endedAt: values.endedAt || undefined,
    currency: values.currency,
  };

  await createMutation
    .mutateAsync({ data: payload })
    .then(async () => {
      displaySuccess({
        text: t("messages.fundingGoal.created"),
      });
      await router.push(extend({ name: "admin-funding-goals" }));
    })
    .catch((error) => {
      console.error("Error creating funding goal:", error);
      displayAlert({ text: t("messages.fundingGoal.createFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-funding-goals" }));
};
</script>

<template>
  <BreadCrumbs
    :crumbs="[
      {
        to: { name: 'admin-supporter-contributions' },
        label: t('headlines.admin.supporterContributions.index'),
      },
      {
        to: { name: 'admin-funding-goals' },
        label: t('headlines.admin.fundingGoals.index'),
      },
    ]"
  />
  <Heading hero>{{ t("headlines.admin.fundingGoals.new") }}</Heading>
  <form id="admin-funding-goal-create-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="title"
          v-bind="titleProps"
          translation-key="fundingGoal.title"
          name="title"
        />
        <FormInput
          v-model="amount"
          v-bind="amountProps"
          :type="InputTypesEnum.NUMBER"
          :step="0.01"
          translation-key="fundingGoal.amount"
          name="amount"
        />
        <FormDatePicker
          v-model="effectiveFrom"
          v-bind="effectiveFromProps"
          translation-key="fundingGoal.effectiveFrom"
          name="effectiveFrom"
        />
        <FormDatePicker
          v-model="endedAt"
          v-bind="endedAtProps"
          :min-date="effectiveFrom || undefined"
          translation-key="fundingGoal.endedAt"
          name="endedAt"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormTextarea
          v-model="description"
          v-bind="descriptionProps"
          translation-key="fundingGoal.description"
          name="description"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-funding-goal-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
