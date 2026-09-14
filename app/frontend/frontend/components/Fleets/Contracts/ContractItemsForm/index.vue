<script lang="ts">
export default {
  name: "FleetContractsItemsForm",
};
</script>

<script lang="ts" setup>
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BasePill from "@/shared/components/base/Pill/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Fleet,
  type FleetContractDetail,
  type FleetContractItem,
  type FleetContractItemInput,
  type FleetContractKindEnum,
  FleetContractQualityMatchEnum,
  useDestroyFleetContractItem,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  // Absent while the contract is still being written: the goods are then held
  // here and saved with it, because a contract with nothing to deliver cannot
  // be published and sending the author to a second form is the long way
  // round.
  contract?: FleetContractDetail;
  kind: FleetContractKindEnum;
  drafts?: FleetContractItemInput[];
};

const props = defineProps<Props>();

const emit = defineEmits<{
  changed: [];
  "update:drafts": [FleetContractItemInput[]];
}>();

const { t } = useI18n();
const comlink = useComlink();
const { displayAlert } = useAppNotifications();

const saved = computed(() => props.contract != null);

// One shape for the list whichever side it came from: a saved line carries an
// id, a draft is identified by where it sits.
type Row = FleetContractItem & { draftIndex?: number };

const rows = computed<Row[]>(() => {
  if (props.contract) return props.contract.items as Row[];

  return (props.drafts ?? []).map(
    (draft, index) =>
      ({
        ...draft,
        id: `draft-${index}`,
        draftIndex: index,
        item: null,
      }) as unknown as Row,
  );
});

// The asking happens in the modal, which has the room for the catalogue
// pickers and the grade rules that a one-line create row does not.
const openItemModal = (item?: Row) => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Contracts/ContractItemModal/index.vue"),
    props: {
      fleet: props.fleet,
      contract: props.contract,
      kind: props.kind,
      item,
      // Present only while the contract is unsaved, and what tells the modal
      // to hand its values back instead of posting them.
      onDraft: saved.value
        ? undefined
        : (values: FleetContractItemInput) => {
            const next = [...(props.drafts ?? [])];

            if (item?.draftIndex != null) {
              next[item.draftIndex] = values;
            } else {
              next.push(values);
            }

            emit("update:drafts", next);
          },
    },
  });
};

const destroyItem = useDestroyFleetContractItem();

const onDestroy = async (item: Row) => {
  if (!props.contract) {
    emit(
      "update:drafts",
      (props.drafts ?? []).filter((_, index) => index !== item.draftIndex),
    );

    return;
  }

  await destroyItem
    .mutateAsync({
      fleetSlug: props.fleet.slug,
      fleetContractSlug: props.contract.slug,
      id: item.id,
    })
    .then(() => emit("changed"))
    .catch(() => {
      displayAlert({
        text: t("messages.fleets.contract.item.destroy.failure"),
      });
    });
};

const itemSavedComlink = ref<() => void>();

onMounted(() => {
  itemSavedComlink.value = comlink.on("fleet-contract-item-saved", () =>
    emit("changed"),
  );
});

onUnmounted(() => {
  itemSavedComlink.value?.();
});

const qualityLabel = (item: Row) =>
  t(
    item.qualityMatch === FleetContractQualityMatchEnum.EXACT
      ? "labels.fleets.contracts.exactQuality"
      : "labels.fleets.contracts.minQuality",
    { value: item.quality as number },
  );
</script>

<template>
  <div class="contract-items">
    <InlineEditableList
      data-test="contract-items"
      :items="rows"
      :empty-name="t('headlines.fleets.contracts.items')"
      :confirm-destroy-text="t('messages.confirm.fleets.contractItem.destroy')"
      hide-edit
      @destroy="onDestroy"
    >
      <template #display="{ item }">
        <BasePill :variant="PillVariantsEnum.NEUTRAL" uppercase margin-right>
          {{ t(`labels.logistics.categories.${item.category}`) }}
        </BasePill>
        <span class="contract-items__name">{{ item.name }}</span>
        <span class="contract-items__quantity">
          {{ Number(item.quantity) }}
          {{ t(`labels.logistics.units.${item.unit}`) }}
        </span>
        <!-- Whether this is a real catalogue entry or a name somebody typed. -->
        <span v-if="item.item" class="contract-items__reference">
          <i class="fa-duotone fa-link" />
          {{ t(`labels.fleets.contracts.itemTypes.${item.item.type}`) }}
        </span>
        <span v-if="item.quality != null" class="contract-items__quality">
          {{ qualityLabel(item as Row) }}
        </span>
      </template>

      <!-- Editing reopens the modal rather than an inline row, for the same
           reason creating does. The list's own edit affordance stays off. -->
      <template #actions="{ item }">
        <Btn data-test="edit-item" @click="openItemModal(item as Row)">
          <i class="fa-duotone fa-pencil" />
        </Btn>
      </template>
    </InlineEditableList>

    <Btn data-test="add-item" @click="openItemModal()">
      <i class="fa-duotone fa-plus" />
      {{ t("actions.fleets.contracts.addItem") }}
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
