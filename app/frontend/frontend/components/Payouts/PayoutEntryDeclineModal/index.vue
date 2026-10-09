<script lang="ts">
export default {
  name: "PayoutsPayoutEntryDeclineModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnTypesEnum,
} from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import { usePayoutCurrency } from "@/frontend/composables/usePayoutCurrency";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useDeclinePayoutEntry as useDeclinePayoutEntryMutation,
  type PayoutEntry,
  type TourCurrencyEnum,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  entry: PayoutEntry;
  currency?: TourCurrencyEnum;
};

const props = withDefaults(defineProps<Props>(), { currency: undefined });

const { t } = useI18n();
const { formatAmount } = usePayoutCurrency(() => props.currency);
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const initialValues = { reason: "" };

const { defineField, handleSubmit, values } = useForm({
  initialValues,
});

// Read by AppModal, which asks before a close would throw typed input away.
defineExpose({ dirty: useFormDirty(values, initialValues) });

const [reason, reasonProps] = defineField("reason");

const declineMutation = useDeclinePayoutEntryMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await declineMutation
    .mutateAsync({
      payoutLedgerId: props.payoutLedgerId,
      id: props.entry.id,
      data: { reason: String(values.reason ?? "").trim() || null },
    })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.expenseDeclined") });
      comlink.emit("payout-ledger-changed");
      comlink.emit("close-modal", true);
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="t('headlines.payouts.declineExpense')">
    <form id="payout-entry-decline-form" @submit.prevent="onSubmit">
      <p class="payout-entry-decline__summary">
        {{ entry.description }} · {{ entry.participant?.displayName }} ·
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span v-html="formatAmount(Number(entry.amount ?? 0))" />
      </p>
      <FormTextarea
        v-model="reason"
        name="reason"
        v-bind="reasonProps"
        :label="t('labels.payouts.declineReason')"
      />
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="payout-entry-decline-form"
        :loading="submitting"
        :size="BtnSizesEnum.LG"
        :tone="BtnTonesEnum.DANGER"
        data-test="payout-entry-decline-submit"
      >
        {{ t("actions.payouts.declineExpense") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.payout-entry-decline__summary {
  margin: 0 0 16px;
  color: var(--color-text-dim, #959595);
}
</style>
