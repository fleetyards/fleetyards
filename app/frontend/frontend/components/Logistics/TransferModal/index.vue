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
  BtnTonesEnum,
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
import type {
  TransferSource,
  TransferTargetKind,
  TransferTargetOption,
} from "./types";

type Props = {
  source: TransferSource;
  // The positions the reader chose -- one row, or a bulk selection. Never the
  // whole inventory: a hold with fifty positions made a modal nobody could use.
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
const targetValue = ref<string | undefined>();

// The stock list is grouped per quality, so one position can arrive as several
// rows -- mined ore at two grades is two rows carrying one `id`. They are one
// thing to move, and the amount available is their sum, which is what
// `stock_positions` reports server-side and what the withdrawal is checked
// against. Collapsing them here is also what makes a bulk selection mean the
// position rather than one of its grades.
//
// Only positions holding something can move; an emptied one still resolves as a
// record, which is why it can appear in a list at all.
const movable = computed(() => {
  const byPosition = new Map<string, InventoryStockPosition>();

  props.positions.forEach((position) => {
    const existing = byPosition.get(position.id);

    if (existing) {
      existing.netQuantity =
        Number(existing.netQuantity) + Number(position.netQuantity);
      return;
    }

    byPosition.set(position.id, { ...position });
  });

  return [...byPosition.values()].filter(
    (position) => Number(position.netQuantity) > 0,
  );
});

// Trimming a bulk selection is removing a line, not unticking a box: the
// reader already chose these rows, so every one of them is going unless they
// say otherwise.
const removed = ref<Set<string>>(new Set());
const quantities = ref<Record<string, string>>({});

// Every line starts at its whole quantity: the reader picked these rows to move
// them, and moving all of it is the common case.
watchEffect(() => {
  movable.value.forEach((position) => {
    if (quantities.value[position.id] === undefined) {
      quantities.value[position.id] = String(position.netQuantity);
    }
  });
});

// Users and fleets are separate choices, not one mixed list: they are different
// kinds of address, and a list holding both makes the reader scan for which is
// which. The kind picks the list; the list is searchable, because a fleet can
// have hundreds of members.
//
// This iteration reaches only what the reader already shares a fleet with --
// which is also what a `known` transfer policy means server-side, so the picker
// and the gate agree on who counts. Arbitrary users and fleets are the API's to
// accept and are not offered here yet.
const KINDS: TransferTargetKind[] = ["inventory", "fleet", "user"];

const availableKinds = computed(() =>
  KINDS.filter((kind) => props.targets.some((target) => target.kind === kind)),
);

const targetKind = ref<TransferTargetKind | undefined>();

watchEffect(() => {
  if (targetKind.value && availableKinds.value.includes(targetKind.value))
    return;

  targetKind.value = availableKinds.value[0];
});

const kindOptions = computed<FilterOption[]>(() =>
  availableKinds.value.map((kind) => ({
    value: kind,
    label: t(`labels.logistics.transferKinds.${kind}`),
  })),
);

const targetOptions = computed<FilterOption[]>(() =>
  props.targets
    .filter((target) => target.kind === targetKind.value)
    .map((target) => ({ value: target.value, label: target.label })),
);

// Picks the first option, and re-picks when a kind change leaves the old
// selection pointing into a list it is no longer part of. `immediate`, because
// the first list is exactly that case -- without it nothing is selected until
// the reader touches the kind picker.
watch(
  targetOptions,
  (options) => {
    if (options.some((option) => option.value === targetValue.value)) return;

    targetValue.value = options[0]?.value as string | undefined;
  },
  { immediate: true },
);

const selectedTarget = computed(() =>
  props.targets.find((target) => target.value === targetValue.value),
);

// What the receiving side will see. A target the sender may write to is carried
// out on the spot; anything else has to be answered first.
const needsAnswer = computed(() => selectedTarget.value?.needsAnswer ?? false);

const chosen = computed(() =>
  movable.value.filter((position) => !removed.value.has(position.id)),
);

const multiple = computed(() => chosen.value.length > 1);

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

const maxFor = (position: InventoryStockPosition) =>
  Number(position.netQuantity);

const atMax = (position: InventoryStockPosition) =>
  quantityFor(position) === maxFor(position);

const resetToMax = (position: InventoryStockPosition) => {
  quantities.value[position.id] = String(maxFor(position));
};

const remove = (position: InventoryStockPosition) => {
  removed.value = new Set(removed.value).add(position.id);
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
        v-if="kindOptions.length > 1"
        v-model="targetKind"
        name="targetKind"
        :options="kindOptions"
        :searchable="false"
        :label="t('labels.logistics.transferTargetKind')"
        data-test="transfer-target-kind"
      />

      <BaseSelect
        v-model="targetValue"
        name="target"
        searchable
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

      <div v-else class="transfer-lines">
        <div
          v-for="position in chosen"
          :key="position.id"
          class="transfer-line"
          :data-test="`transfer-line-${position.slug}`"
        >
          <span class="transfer-line-name">{{ position.name }}</span>

          <div class="transfer-line-amount">
            <FormInput
              v-model="quantities[position.id]"
              type="number"
              no-placeholder
              inline
              :min="0"
              :max="maxFor(position)"
              :name="`quantity-${position.id}`"
              :label="t('labels.logistics.quantity')"
            />
            <span class="transfer-line-unit">
              {{ t(`labels.logistics.units.${position.unit}`) }}
            </span>
            <span class="transfer-line-max">
              / {{ position.netQuantity }}
            </span>

            <Btn
              v-if="!atMax(position)"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :aria-label="t('actions.logistics.resetToMax')"
              :title="t('actions.logistics.resetToMax')"
              :data-test="`transfer-reset-${position.slug}`"
              @click="resetToMax(position)"
            >
              <i class="fa-duotone fa-arrow-rotate-left" />
            </Btn>

            <Btn
              v-if="multiple"
              :size="BtnSizesEnum.SM"
              :variant="BtnVariantsEnum.BARE"
              :tone="BtnTonesEnum.DANGER"
              :aria-label="t('actions.logistics.removeLine')"
              :title="t('actions.logistics.removeLine')"
              :data-test="`transfer-remove-${position.slug}`"
              @click="remove(position)"
            >
              <i class="fa fa-times" />
            </Btn>
          </div>

          <p
            v-if="overStock(position)"
            class="transfer-line-error"
            :data-test="`transfer-over-stock-${position.slug}`"
          >
            {{ t("labels.logistics.overStock") }}
          </p>
        </div>
      </div>

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

.transfer-lines {
  margin-bottom: 1.5rem;
}

.transfer-line {
  padding: 0.5rem 0;

  &:not(:last-child) {
    border-bottom: 1px solid rgb(255 255 255 / 8%);
  }
}

.transfer-line-name {
  display: block;
  margin-bottom: 0.25rem;
  font-weight: 600;
}

.transfer-line-amount {
  display: flex;
  gap: 0.5rem;
  align-items: center;
}

.transfer-line-unit,
.transfer-line-max {
  white-space: nowrap;
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
