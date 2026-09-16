<script lang="ts">
export default {
  name: "AdminSupporterContributionCreatePage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import {
  type FilterOption,
  type SupporterContributionInput,
  useCreateSupporterContribution,
  getSupporterContributionsQueryKey,
  SupporterContributionSourceEnum,
} from "@/services/fyAdminApi";
import { useForm } from "vee-validate";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormDatePicker from "@/shared/components/base/FormDatePicker/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import FormActions from "@/shared/components/base/FormActions/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import UserSelect from "@/admin/components/base/UserSelect/index.vue";
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
  name?: string;
  amount?: number;
  startedAt: string;
  endedAt?: string;
  recurring: boolean;
  anonymous: boolean;
  note?: string;
  payerEmail?: string;
  claimKey?: string;
  userId?: string;
  source: SupporterContributionSourceEnum;
};

const validationSchema = {
  amount: "required",
  startedAt: "required",
};

const initialValues = ref<FormValues>({
  name: "",
  amount: undefined,
  startedAt: todayIsoDateLocal(),
  recurring: false,
  anonymous: false,
  source: SupporterContributionSourceEnum.OTHER,
});

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
const [payerEmail, payerEmailProps] = defineField("payerEmail");
const [claimKey, claimKeyProps] = defineField("claimKey");
const [userId, userIdProps] = defineField("userId");
const [source, sourceProps] = defineField("source");

const sourceOptions = computed<FilterOption[]>(() =>
  Object.values(SupporterContributionSourceEnum).map((value) => ({
    value,
    label: t(`labels.admin.supporterContributions.source.${value}`),
  })),
);

const submitting = ref(false);

const createMutation = useCreateSupporterContribution({
  mutation: {
    onSettled: () => {
      void queryClient.invalidateQueries({
        queryKey: getSupporterContributionsQueryKey(),
      });
    },
  },
});

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const payload: SupporterContributionInput = {
    name: values.name || undefined,
    amountCents: toCents(values.amount),
    startedAt: values.startedAt,
    endedAt: (values.recurring && values.endedAt) || undefined,
    recurring: values.recurring,
    anonymous: values.anonymous,
    note: values.note || undefined,
    payerEmail: values.payerEmail || undefined,
    claimKey: values.claimKey || undefined,
    userId: values.userId || undefined,
    source: values.source,
  };

  await createMutation
    .mutateAsync({ data: payload })
    .then(async () => {
      displaySuccess({
        text: t("messages.supporterContribution.created"),
      });
      await router.push(extend({ name: "admin-supporter-contributions" }));
    })
    .catch((error) => {
      console.error("Error creating supporter contribution:", error);
      displayAlert({ text: t("messages.supporterContribution.createFailed") });
    })
    .finally(() => {
      submitting.value = false;
    });
});

const handleCancel = async () => {
  await router.push(extend({ name: "admin-supporter-contributions" }));
};
</script>

<template>
  <Heading hero>{{ t("headlines.admin.supporterContributions.new") }}</Heading>
  <form
    id="admin-supporter-contribution-create-form"
    @submit.prevent="onSubmit"
  >
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
          align-with-fields
        />
        <FormToggle
          v-model="anonymous"
          v-bind="anonymousProps"
          translation-key="supporterContribution.anonymous"
          name="anonymous"
        />
        <UserSelect
          v-model="userId"
          v-bind="userIdProps"
          :label="t('labels.supporterContribution.user')"
          :no-label="false"
          :multiple="false"
          value-attr="id"
          name="userId"
        />
        <BaseSelect
          v-model="source"
          v-bind="sourceProps"
          :label="t('labels.supporterContribution.source')"
          :no-label="false"
          :options="sourceOptions"
          :multiple="false"
          name="source"
        />
        <FormInput
          v-model="payerEmail"
          v-bind="payerEmailProps"
          :type="InputTypesEnum.EMAIL"
          translation-key="supporterContribution.payerEmail"
          name="payerEmail"
        />
        <FormInput
          v-model="claimKey"
          v-bind="claimKeyProps"
          translation-key="supporterContribution.claimKey"
          name="claimKey"
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
      form-id="admin-supporter-contribution-create-form"
      :dirty="meta.dirty || meta.touched"
      @cancel="handleCancel"
    />
  </form>
</template>
