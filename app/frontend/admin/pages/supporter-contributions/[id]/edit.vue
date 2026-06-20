<script lang="ts">
export default {
  name: "AdminSupporterContributionEditPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type SupporterContribution,
  type SupporterContributionInput,
  useUpdateSupporterContribution,
  getSupporterContributionsQueryKey,
  getSupporterContributionQueryKey,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import { useBreadCrumbs } from "@/shared/composables/useBreadCrumbs";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  supporterContribution: SupporterContribution;
};

const props = defineProps<Props>();

const { t } = useI18n();
const router = useRouter();
const { extend } = useBreadCrumbs();
const { displaySuccess, displayAlert } = useAppNotifications();
const queryClient = useQueryClient();

type FormValues = {
  name?: string;
  amount: number;
  startedAt: string;
  endedAt?: string;
  recurring: boolean;
  anonymous: boolean;
  note?: string;
  currency?: string;
};

const initialValues = ref<FormValues>({
  name: props.supporterContribution.name,
  amount: props.supporterContribution.amountCents / 100,
  startedAt: props.supporterContribution.startedAt,
  endedAt: props.supporterContribution.endedAt,
  recurring: props.supporterContribution.recurring,
  anonymous: props.supporterContribution.anonymous,
  note: props.supporterContribution.note,
  currency: props.supporterContribution.currency,
});

const validationSchema = {
  amount: "required",
  startedAt: "required",
};

const { defineField, handleSubmit, meta } = useForm<FormValues>({
  initialValues: initialValues.value,
  validationSchema,
});

const [name, nameProps] = defineField("name");
const [amount, amountProps] = defineField("amount");
const [startedAt, startedAtProps] = defineField("startedAt");
const [endedAt, endedAtProps] = defineField("endedAt");
const [recurring, recurringProps] = defineField("recurring");
const [anonymous, anonymousProps] = defineField("anonymous");
const [note, noteProps] = defineField("note");

const submitting = ref(false);

const updateMutation = useUpdateSupporterContribution({
  mutation: {
    onSettled: () => {
      void Promise.all([
        queryClient.invalidateQueries({
          queryKey: getSupporterContributionsQueryKey(),
        }),
        queryClient.invalidateQueries({
          queryKey: getSupporterContributionQueryKey(
            props.supporterContribution.id,
          ),
        }),
      ]);
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const payload: SupporterContributionInput = {
    name: values.name || undefined,
    amountCents: Math.round(Number(values.amount) * 100),
    startedAt: values.startedAt,
    endedAt: (values.recurring && values.endedAt) || undefined,
    recurring: values.recurring,
    anonymous: values.anonymous,
    note: values.note || undefined,
    currency: values.currency,
  };

  await updateMutation
    .mutateAsync({
      id: props.supporterContribution.id,
      data: payload,
    })
    .then(() => {
      displaySuccess({
        text: t("messages.supporterContribution.updated"),
      });
    })
    .catch((error) => {
      console.error("Error updating supporter contribution:", error);
      displayAlert({ text: t("messages.supporterContribution.updateFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(
    extend({
      name: "admin-supporter-contributions",
      hash: `#${props.supporterContribution.id}`,
    }),
  );
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.supporterContributions.edit") }}</Heading>
  <form id="admin-supporter-contribution-edit-form" @submit.prevent="onSubmit">
    <div class="row">
      <div class="col-12 col-md-6">
        <FormInput
          v-model="name"
          v-bind="nameProps"
          translation-key="supporterContribution.name"
          name="name"
        />
        <FormInput
          v-model="amount"
          v-bind="amountProps"
          :type="InputTypesEnum.NUMBER"
          :step="0.01"
          translation-key="supporterContribution.amount"
          name="amount"
        />
        <FormDatePicker
          v-model="startedAt"
          v-bind="startedAtProps"
          translation-key="supporterContribution.startedAt"
          name="startedAt"
        />
        <FormDatePicker
          v-if="recurring"
          v-model="endedAt"
          v-bind="endedAtProps"
          :min-date="startedAt || undefined"
          translation-key="supporterContribution.endedAt"
          name="endedAt"
        />
      </div>
      <div class="col-12 col-md-6">
        <FormToggle
          v-model="recurring"
          v-bind="recurringProps"
          translation-key="supporterContribution.recurring"
          name="recurring"
        />
        <FormToggle
          v-model="anonymous"
          v-bind="anonymousProps"
          translation-key="supporterContribution.anonymous"
          name="anonymous"
        />
        <FormTextarea
          v-model="note"
          v-bind="noteProps"
          translation-key="supporterContribution.note"
          name="note"
        />
      </div>
    </div>
    <FormActions
      :submitting="submitting"
      form-id="admin-supporter-contribution-edit-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
