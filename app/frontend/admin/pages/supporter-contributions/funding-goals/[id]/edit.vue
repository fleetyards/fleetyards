<script lang="ts">
export default {
  name: "AdminFundingGoalEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import {
  type FundingGoal,
  type FundingGoalInput,
  useUpdateFundingGoal,
  getFundingGoalsQueryKey,
  getFundingGoalQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { toCents } from "@/shared/utils/currencyHelpers";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  fundingGoal: FundingGoal;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

type FormValues = {
  title: string;
  description?: string;
  amount: number;
  effectiveFrom: string;
  endedAt?: string;
  currency: string;
};

const initialValues = ref<FormValues>({
  title: props.fundingGoal.title,
  description: props.fundingGoal.description,
  amount: props.fundingGoal.amountCents / 100,
  effectiveFrom: props.fundingGoal.effectiveFrom,
  endedAt: props.fundingGoal.endedAt,
  currency: props.fundingGoal.currency,
});

const validationSchema = {
  title: "required",
  amount: "required",
  effectiveFrom: "required",
};

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

const updateMutation = useUpdateFundingGoal({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getFundingGoalsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getFundingGoalQueryKey(props.fundingGoal.id),
        }),
      ]);
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

  await updateMutation
    .mutateAsync({
      id: props.fundingGoal.id,
      data: payload,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.fundingGoal.updated"),
      });
    })
    .catch((error) => {
      console.error("Error updating funding goal:", error);
      displayAlert({ text: t("messages.fundingGoal.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-funding-goals",
      hash: `#${props.fundingGoal.id}`,
    }),
  );
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
  <Heading hero>{{ t("headlines.admin.fundingGoals.edit") }}</Heading>
  <form id="admin-funding-goal-edit-form" @submit.prevent="onSubmit">
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
      form-id="admin-funding-goal-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
