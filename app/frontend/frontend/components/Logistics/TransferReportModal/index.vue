<script lang="ts">
export default {
  name: "LogisticsTransferReportModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  type FilterOption,
  type InventoryTransfer,
  InventoryTransferReportReasonEnum,
} from "@/services/fyApi";

type Props = {
  transfer: InventoryTransfer;
  onReport: (payload: { reason: string; note?: string }) => Promise<unknown>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const submitting = ref(false);
const reason = ref<string>(InventoryTransferReportReasonEnum.SPAM);
const note = ref("");

const options = computed<FilterOption[]>(() =>
  Object.values(InventoryTransferReportReasonEnum).map((value) => ({
    value,
    label: t(`labels.logistics.reportReasons.${value}`),
  })),
);

// The API requires a note for "other" -- there is nothing else to go on.
const noteRequired = computed(
  () => reason.value === InventoryTransferReportReasonEnum.OTHER,
);

const invalid = computed(() => noteRequired.value && note.value.trim() === "");

const onSubmit = async () => {
  if (invalid.value) return;

  submitting.value = true;

  try {
    await props.onReport({
      reason: reason.value,
      note: note.value || undefined,
    });
    comlink.emit("close-modal");
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.logistics.reportTransfer')">
    <form id="report-transfer-form" @submit.prevent="onSubmit">
      <p class="report-hint">
        {{ t("messages.logistics.transfer.reportHint") }}
      </p>

      <BaseSelect
        v-model="reason"
        name="reason"
        :options="options"
        :searchable="false"
        :label="t('labels.logistics.reportReason')"
        data-test="report-reason"
      />

      <FormInput
        v-model="note"
        name="note"
        :label="t('labels.logistics.transferNote')"
        data-test="report-note"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :disabled="invalid"
          :tone="BtnTonesEnum.DANGER"
          :size="BtnSizesEnum.LG"
          data-test="report-submit"
          @click="onSubmit"
        >
          {{ t("actions.logistics.reportTransfer") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.report-hint {
  margin-bottom: 1rem;
  opacity: 0.75;
}
</style>
