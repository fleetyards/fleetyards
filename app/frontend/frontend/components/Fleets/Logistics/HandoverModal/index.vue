<script lang="ts">
export default {
  name: "FleetLogisticsHandoverModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import BaseSelect, {
  type BaseSelectParams,
} from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useFormDirty } from "@/shared/composables/useFormDirty";
import {
  type FilterOption,
  type Fleet,
  type FleetInventory,
  type FleetMember,
  fleetMembers as fetchFleetMembers,
  useHandOverFleetInventoryStock,
} from "@/services/fyApi";
import {
  UNASSIGNED,
  holderIdFor,
  holderValue,
  useStockHolders,
} from "@/frontend/composables/useStockHolders";
import type { InventoryStockRecord } from "@/frontend/types/logistics";

type Props = {
  fleet: Fleet;
  inventory: FleetInventory;
  // One lot of the stock list: the grade, and for a crafted part what it was
  // made from, are what the hand-over moves.
  lot: InventoryStockRecord;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { displaySuccess, displayAlert } = useAppNotifications();
const { holderName } = useStockHolders();

const shares = computed(() => props.lot.holders ?? []);

const from = ref<string | undefined>(
  shares.value[0] ? holderValue(shares.value[0]) : undefined,
);
const to = ref<string | undefined>();
const quantity = ref<number | undefined>();
const submitting = ref(false);

const unitLabel = computed(() => t(`labels.logistics.units.${props.lot.unit}`));

const fromOptions = computed<FilterOption[]>(() =>
  shares.value.map((share) => ({
    value: holderValue(share),
    label: `${holderName(share)} · ${share.netQuantity} ${unitLabel.value}`,
  })),
);

const available = computed(
  () =>
    shares.value.find((share) => holderValue(share) === from.value)
      ?.netQuantity ?? 0,
);

// The whole share is the usual case: whoever is logging off hands over all of
// it.
watch(
  available,
  (value) => {
    quantity.value = value || undefined;
  },
  { immediate: true },
);

const fetchMembers = (params: BaseSelectParams<FilterOption>) =>
  fetchFleetMembers(props.fleet.slug, {
    q: { usernameCont: params.search || undefined },
  });

// The unassigned share is a place stock can go as well as come from, and the
// giver is left out: handing a share to its own holder moves nothing.
const formatMembers = (response: { items: FleetMember[] }) =>
  [
    { label: t("labels.logistics.unassigned"), value: UNASSIGNED },
    ...(response.items || []).map((member) => ({
      label: member.username,
      value: member.userId || "",
    })),
  ].filter((option) => option.value !== from.value);

watch(from, (value) => {
  if (to.value === value) to.value = undefined;
});

const invalid = computed(
  () =>
    !from.value ||
    !to.value ||
    from.value === to.value ||
    !quantity.value ||
    Number(quantity.value) <= 0 ||
    Number(quantity.value) > Number(available.value),
);

const state = computed(() => ({
  from: from.value,
  to: to.value,
  quantity: quantity.value,
}));

useModalDirty(useFormDirty(state, state.value));

const mutation = useHandOverFleetInventoryStock();

const onSubmit = async () => {
  if (invalid.value || !props.lot.slug) return;

  submitting.value = true;

  try {
    await mutation.mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetInventorySlug: props.inventory.slug,
      slug: props.lot.slug,
      data: {
        fromHolderId: holderIdFor(from.value),
        toHolderId: holderIdFor(to.value),
        quantity: Number(quantity.value),
        quality: props.lot.quality ?? null,
        craftedBlueprintId: props.lot.crafted?.blueprint.id ?? null,
        craftedQualities: props.lot.crafted?.qualities ?? null,
      },
    });

    displaySuccess({ text: t("messages.logistics.handover.success") });
    comlink.emit("fleet-inventory-item-created");
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({ text: t("messages.logistics.handover.failure") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.logistics.handover', { name: lot.name })">
    <form id="handover-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="from"
        name="from"
        :options="fromOptions"
        :searchable="false"
        :label="t('labels.logistics.handoverFrom')"
        data-test="handover-from"
      />

      <BaseSelect
        v-model="to"
        name="to"
        searchable
        :query-fn="fetchMembers"
        :query-response-formatter="formatMembers"
        :label="t('labels.logistics.handoverTo')"
        data-test="handover-to"
      />

      <FormInput
        v-model="quantity"
        name="quantity"
        :type="InputTypesEnum.NUMBER"
        :label="t('labels.logistics.quantity')"
        :min="0"
        :max="available"
        no-placeholder
        data-test="handover-quantity"
      >
        <template #suffix>
          <span class="base-input__suffix-text">{{ unitLabel }}</span>
        </template>
      </FormInput>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="handover-form"
        :loading="submitting"
        :disabled="invalid"
        data-test="handover-submit"
      >
        {{ t("actions.logistics.handover") }}
      </Btn>
    </template>
  </Modal>
</template>
