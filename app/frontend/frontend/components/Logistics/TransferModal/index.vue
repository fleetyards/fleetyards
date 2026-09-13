<script lang="ts">
export default {
  name: "LogisticsTransferModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  BtnSizesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type FilterOption,
  type InventoryStockPosition,
  type InventoryTransferCreateInput,
} from "@/services/fyApi";
import type { TransferSource, TransferTargetOption } from "./types";

type Props = {
  source: TransferSource;
  positions: InventoryStockPosition[];
  targets: TransferTargetOption[];
  onSend: (payload: InventoryTransferCreateInput) => Promise<unknown>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const submitting = ref(false);
const note = ref("");
const targetValue = ref<string | undefined>(props.targets[0]?.value);

// Only positions holding something can move. An emptied one still resolves as a
// record, which is why it can appear in the list this is handed.
const movable = computed(() =>
  props.positions.filter((position) => Number(position.netQuantity) > 0),
);

const selected = ref<Record<string, boolean>>({});
const quantities = ref<Record<string, string>>({});

// Default every line to the whole position: unloading a hold is the common
// case, and a part of one is the exception.
watchEffect(() => {
  movable.value.forEach((position) => {
    if (quantities.value[position.id] === undefined) {
      quantities.value[position.id] = String(position.netQuantity);
    }
  });
});

const targetOptions = computed<FilterOption[]>(() =>
  props.targets.map((target) => ({
    value: target.value,
    label: target.label,
  })),
);

const selectedTarget = computed(() =>
  props.targets.find((target) => target.value === targetValue.value),
);

// What the receiving side will see. A target the sender may write to is carried
// out on the spot; anything else has to be answered first.
const needsAnswer = computed(() => selectedTarget.value?.needsAnswer ?? false);

const chosen = computed(() =>
  movable.value.filter((position) => selected.value[position.id]),
);

const quantityFor = (position: InventoryStockPosition) =>
  Number(quantities.value[position.id] ?? 0);

const overStock = (position: InventoryStockPosition) =>
  quantityFor(position) > Number(position.netQuantity);

// All-or-nothing, the same rule the API applies: one bad line refuses the whole
// shipment, so the button does not offer to send a partly valid one.
const invalid = computed(
  () =>
    !selectedTarget.value ||
    chosen.value.length === 0 ||
    chosen.value.some(
      (position) => quantityFor(position) <= 0 || overStock(position),
    ),
);

const toggleAll = () => {
  const turningOn = chosen.value.length < movable.value.length;

  movable.value.forEach((position) => {
    selected.value[position.id] = turningOn;
  });
};

const onSubmit = async () => {
  const target = selectedTarget.value;
  if (!target || invalid.value) return;

  submitting.value = true;

  try {
    await props.onSend({
      sourceInventoryId: props.source.id,
      lines: chosen.value.map((position) => ({
        positionId: position.id,
        quantity: quantityFor(position),
      })),
      note: note.value || undefined,
      ...target.payload,
    });

    comlink.emit("close-modal");
  } catch {
    displayAlert({ text: t("messages.logistics.transfer.create.failure") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.logistics.transfer')">
    <form id="transfer-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="targetValue"
        name="target"
        :options="targetOptions"
        :label="t('labels.logistics.transferTarget')"
        data-test="transfer-target"
      />

      <p v-if="needsAnswer" class="transfer-hint" data-test="transfer-hint">
        {{ t("messages.logistics.transfer.needsAnswer") }}
      </p>

      <p
        v-if="movable.length === 0"
        class="transfer-empty"
        data-test="transfer-empty"
      >
        {{ t("labels.logistics.noStock") }}
      </p>

      <template v-else>
        <div class="transfer-lines-head">
          <span>{{ t("labels.logistics.positions") }}</span>
          <Btn
            :size="BtnSizesEnum.SM"
            :variant="BtnVariantsEnum.BARE"
            data-test="transfer-toggle-all"
            @click="toggleAll"
          >
            {{ t("actions.logistics.selectAll") }}
          </Btn>
        </div>

        <div
          v-for="position in movable"
          :key="position.id"
          class="transfer-line"
          :data-test="`transfer-line-${position.slug}`"
        >
          <label class="transfer-line-label">
            <input
              v-model="selected[position.id]"
              type="checkbox"
              :data-test="`transfer-select-${position.slug}`"
            />
            <span class="transfer-line-name">{{ position.name }}</span>
            <span class="transfer-line-stock">
              {{ position.netQuantity }}
              {{ t(`labels.logistics.units.${position.unit}`) }}
            </span>
          </label>

          <template v-if="selected[position.id]">
            <FormInput
              v-model="quantities[position.id]"
              type="number"
              no-placeholder
              :min="0"
              :max="Number(position.netQuantity)"
              :name="`quantity-${position.id}`"
              :label="t('labels.logistics.quantity')"
            />
            <p
              v-if="overStock(position)"
              class="transfer-line-error"
              :data-test="`transfer-over-stock-${position.slug}`"
            >
              {{ t("labels.logistics.overStock") }}
            </p>
          </template>
        </div>
      </template>

      <FormInput
        v-model="note"
        name="note"
        no-placeholder
        :label="t('labels.logistics.transferNote')"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :disabled="invalid"
          :size="BtnSizesEnum.LG"
          data-test="transfer-submit"
          @click="onSubmit"
        >
          {{
            needsAnswer
              ? t("actions.logistics.sendTransfer")
              : t("actions.logistics.moveStock")
          }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.transfer-hint {
  margin-bottom: 1rem;
  opacity: 0.75;
}

.transfer-lines-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 0.5rem;
}

.transfer-line {
  padding: 0.5rem 0;
  border-bottom: 1px solid rgb(255 255 255 / 8%);
}

.transfer-line-label {
  display: flex;
  gap: 0.75rem;
  align-items: center;
  cursor: pointer;
}

.transfer-line-name {
  flex: 1;
}

.transfer-line-stock {
  opacity: 0.7;
}

.transfer-empty {
  margin: 0.5rem 0;
  opacity: 0.75;
}

.transfer-line-error {
  margin: 0.25rem 0 0;
  color: var(--color-danger, #d11b45);
}
</style>
