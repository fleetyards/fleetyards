<script lang="ts">
export default {
  name: "PayoutsPayoutEntryDeclineModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useDeclinePayoutEntry as useDeclinePayoutEntryMutation,
  type PayoutEntry,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  entry: PayoutEntry;
};

const props = defineProps<Props>();

const { t, toUEC } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);

const { defineField, handleSubmit } = useForm({
  initialValues: { reason: "" },
});

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
      comlink.emit("close-modal");
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
        <span v-html="toUEC(Number(entry.amount ?? 0))" />
      </p>
      <FormTextarea
        v-model="reason"
        name="reason"
        v-bind="reasonProps"
        :label="t('labels.payouts.declineReason')"
      />
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LG"
          :tone="BtnTonesEnum.DANGER"
          data-test="payout-entry-decline-submit"
          @click="onSubmit"
        >
          {{ t("actions.payouts.declineExpense") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.payout-entry-decline__summary {
  margin: 0 0 16px;
  color: var(--color-text-dim, #959595);
}
</style>
