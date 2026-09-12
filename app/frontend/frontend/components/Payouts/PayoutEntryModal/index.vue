<script lang="ts">
export default {
  name: "PayoutsPayoutEntryModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import FormTextarea from "@/shared/components/base/FormTextarea/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import { useForm } from "vee-validate";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  useCreatePayoutEntry as useCreatePayoutEntryMutation,
  useUpdatePayoutEntry as useUpdatePayoutEntryMutation,
  useDestroyPayoutEntry as useDestroyPayoutEntryMutation,
  type PayoutEntry,
  type PayoutEntryTypeEnum,
  type PayoutParticipant,
} from "@/services/fyApi";
import type { ApiError } from "@/shared/types/api-error";

type Props = {
  payoutLedgerId: string;
  participants: PayoutParticipant[];
  entry?: PayoutEntry;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();

const submitting = ref(false);
const deleting = ref(false);

const participantOptions = computed(() =>
  props.participants.map((participant) => ({
    value: participant.id,
    label: participant.displayName,
  })),
);

const entryTypeOptions = computed(() => [
  { value: "expense", label: t("labels.payouts.expense") },
  { value: "income", label: t("labels.payouts.income") },
]);

const { defineField, handleSubmit } = useForm({
  initialValues: {
    payoutParticipantId:
      props.entry?.payoutParticipantId ?? props.participants[0]?.id,
    entryType: (props.entry?.entryType ?? "expense") as PayoutEntryTypeEnum,
    amount: props.entry?.amount ?? "",
    description: props.entry?.description ?? "",
    notes: props.entry?.notes ?? "",
  },
});

const [payoutParticipantId] = defineField("payoutParticipantId");
const [entryType] = defineField("entryType");
const [amount, amountProps] = defineField("amount");
const [description, descriptionProps] = defineField("description");
const [notes, notesProps] = defineField("notes");

const createMutation = useCreatePayoutEntryMutation();
const updateMutation = useUpdatePayoutEntryMutation();
const destroyMutation = useDestroyPayoutEntryMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  const data = {
    payoutParticipantId: values.payoutParticipantId as string,
    entryType: values.entryType as PayoutEntryTypeEnum,
    amount: String(values.amount),
    description: values.description as string,
    notes: (values.notes as string) || null,
  };

  const request = props.entry
    ? updateMutation.mutateAsync({
        payoutLedgerId: props.payoutLedgerId,
        id: props.entry.id,
        data,
      })
    : createMutation.mutateAsync({
        payoutLedgerId: props.payoutLedgerId,
        data,
      });

  await request
    .then(() => {
      displaySuccess({
        text: props.entry
          ? t("messages.payouts.entryUpdated")
          : t("messages.payouts.entryCreated"),
      });
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

const onDestroy = async () => {
  if (!props.entry) {
    return;
  }

  deleting.value = true;

  await destroyMutation
    .mutateAsync({ payoutLedgerId: props.payoutLedgerId, id: props.entry.id })
    .then(() => {
      displaySuccess({ text: t("messages.payouts.entryDestroyed") });
      comlink.emit("payout-ledger-changed");
      comlink.emit("close-modal");
    })
    .catch((error: ApiError) => {
      displayAlert({ text: error.response?.data?.message });
    })
    .finally(() => {
      deleting.value = false;
    });
};
</script>

<template>
  <Modal
    :title="
      entry ? t('headlines.payouts.editEntry') : t('headlines.payouts.addEntry')
    "
  >
    <form id="payout-entry-form" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <BaseSelect
            v-model="entryType"
            name="entryType"
            :options="entryTypeOptions"
            :label="t('labels.payouts.entryType')"
            @update:model-value="
              (value) => (entryType = value as PayoutEntryTypeEnum)
            "
          />
        </div>
        <div class="col-12 col-md-6">
          <BaseSelect
            v-model="payoutParticipantId"
            name="payoutParticipantId"
            :options="participantOptions"
            :searchable="true"
            :label="t('labels.payouts.participant')"
            @update:model-value="
              (value) => (payoutParticipantId = value as string)
            "
          />
        </div>
        <div class="col-12 col-md-6">
          <FormInput
            v-model="amount"
            name="amount"
            type="number"
            rules="required"
            v-bind="amountProps"
            :label="t('labels.payouts.amount')"
          />
        </div>
        <div class="col-12 col-md-6">
          <FormInput
            v-model="description"
            name="description"
            rules="required"
            v-bind="descriptionProps"
            :label="t('labels.payouts.description')"
          />
        </div>
        <div class="col-12">
          <FormTextarea
            v-model="notes"
            name="notes"
            v-bind="notesProps"
            :label="t('labels.payouts.notes')"
          />
        </div>
      </div>
    </form>

    <template #footer>
      <div class="modal-actions">
        <Btn
          v-if="entry"
          :tone="BtnTonesEnum.DANGER"
          :size="BtnSizesEnum.LG"
          :loading="deleting"
          :aria-label="t('actions.delete')"
          @click="onDestroy"
        >
          <i class="fa-light fa-trash" />
        </Btn>
        <Btn :loading="submitting" :size="BtnSizesEnum.LG" @click="onSubmit">
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
