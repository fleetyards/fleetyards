<script lang="ts">
export default {
  name: "FleetContractsItemsForm",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  type Fleet,
  type FleetContractDetail,
  type FleetContractItem,
  FleetContractQualityMatchEnum,
  useDestroyFleetContractItem,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  fleet: Fleet;
  contract: FleetContractDetail;
};

const props = defineProps<Props>();
const emit = defineEmits<{ changed: [] }>();

const { t } = useI18n();
const { displayAlert } = useAppNotifications();
const comlink = useComlink();

const destroyItem = useDestroyFleetContractItem();

// Goods are added through a modal, the way the inventory ledger adds an entry:
// the picker, the category and the grade are more than a row of fields, and a
// panel full of them competes with the contract's own form.
const openAddModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Contracts/ContractItemModal/index.vue"),
    props: {
      fleet: props.fleet,
      contract: props.contract,
    },
  });
};

const removeItem = async (item: FleetContractItem) => {
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

const qualityLabel = (item: FleetContractItem) =>
  t(
    item.qualityMatch === FleetContractQualityMatchEnum.EXACT
      ? "labels.fleets.contracts.exactQuality"
      : "labels.fleets.contracts.minQuality",
    { value: item.quality as number },
  );

const itemCreatedComlink = ref<() => void>();

onMounted(() => {
  itemCreatedComlink.value = comlink.on("fleet-contract-item-created", () =>
    emit("changed"),
  );
});

onUnmounted(() => {
  itemCreatedComlink.value?.();
});
</script>

<template>
  <div class="contract-items" data-test="contract-items">
    <!-- Publishing refuses a contract with nothing to deliver, so an empty list
         has to say what it is waiting for rather than just being empty. -->
    <p v-if="!props.contract.items.length" class="contract-items__empty">
      {{ t("empty.fleets.contracts.items") }}
    </p>

    <ul v-else class="contract-items__list">
      <li
        v-for="item in props.contract.items"
        :key="item.id"
        class="contract-items__row"
        data-test="contract-item"
      >
        <span class="contract-items__name">{{ item.name }}</span>
        <!-- What the ledger will be matched against, and whether it is a real
             catalogue entry or a name somebody typed. -->
        <span class="contract-items__category">
          {{ t(`labels.logistics.categories.${item.category}`) }}
        </span>
        <span v-if="item.item" class="contract-items__reference">
          <i class="fa-duotone fa-link" />
          {{ t(`labels.fleets.contracts.itemTypes.${item.item.type}`) }}
        </span>
        <span class="contract-items__quantity">
          {{ Number(item.quantity) }}
          {{ t(`labels.logistics.units.${item.unit}`) }}
        </span>
        <span v-if="item.quality != null" class="contract-items__quality">
          {{ qualityLabel(item) }}
        </span>
        <Btn size="xs" @click="removeItem(item)">
          {{ t("actions.remove") }}
        </Btn>
      </li>
    </ul>

    <Btn data-test="add-contract-item" @click="openAddModal">
      <i class="fa-light fa-plus" />
      <span>{{ t("actions.fleets.contracts.addItem") }}</span>
    </Btn>
  </div>
</template>

<style lang="scss" scoped>
@import "index";
</style>
