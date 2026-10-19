<script lang="ts">
export default {
  name: "HangarAddToInventoryModal",
};
</script>

<script lang="ts" setup>
import { useQueryClient } from "@tanstack/vue-query";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  getHangarEquipmentQueryKey,
  getHangarInventoriesQueryKey,
  getHangarShipComponentsQueryKey,
  useAddPledgeItemsToHangarInventory,
  useHangarInventories,
  type FilterOption,
  type HangarPledgeItem,
} from "@/services/fyApi";

type Props = {
  items: HangarPledgeItem[];
  onAdded?: () => void;
};

const props = withDefaults(defineProps<Props>(), {
  onAdded: undefined,
});

const { t } = useI18n();
const comlink = useComlink();
const queryClient = useQueryClient();
const { displaySuccess, displayInfo, displayAlert } = useAppNotifications();

// The list a user keeps by hand; a ship's cargo is reached through the ship.
const { data: inventories, isLoading } = useHangarInventories({
  perPage: "240",
});

const options = computed<FilterOption[]>(() =>
  (inventories.value?.items ?? []).map((inventory) => ({
    value: inventory.slug,
    label: inventory.name,
  })),
);

const inventorySlug = ref<string>();

watch(
  options,
  (current) => {
    inventorySlug.value ??= current[0]?.value as string | undefined;
  },
  { immediate: true },
);

// An item already added stays where it is: a second add would double it.
const toAdd = computed(() => props.items.filter((item) => !item.inventory));
const alreadyAdded = computed(() =>
  props.items.filter((item) => item.inventory),
);

const LISTED = 8;

const mutation = useAddPledgeItemsToHangarInventory();

const onSubmit = async () => {
  const slug = inventorySlug.value;
  if (!slug || !toAdd.value.length) return;

  try {
    const result = await mutation.mutateAsync({
      hangarInventorySlug: slug,
      data: { pledgeItemIds: toAdd.value.map((item) => item.id) },
    });

    await Promise.all(
      [
        getHangarShipComponentsQueryKey(),
        getHangarEquipmentQueryKey(),
        getHangarInventoriesQueryKey(),
      ].map((queryKey) => queryClient.invalidateQueries({ queryKey })),
    );

    const inventory = options.value.find((option) => option.value === slug);

    // A list shown before another tab added them offers what is already in.
    if (result.addedPledgeItemIds.length) {
      displaySuccess({
        text: t("messages.hangarPledgeItems.addedToInventory", {
          count: result.addedPledgeItemIds.length,
          inventory: inventory?.label,
        }),
      });
    } else {
      displayInfo({
        text: t("texts.hangarPledgeItems.alreadyInInventory", {
          count: result.skippedPledgeItemIds.length,
        }),
      });
    }

    props.onAdded?.();
    comlink.emit("close-modal", true);
  } catch {
    displayAlert({
      text: t("messages.hangarPledgeItems.addToInventoryFailed"),
    });
  }
};
</script>

<template>
  <Modal :title="t('labels.hangarPledgeItems.addToInventory')">
    <form
      v-if="options.length"
      id="add-to-inventory-form"
      class="add-to-inventory"
      @submit.prevent="onSubmit"
    >
      <BaseSelect
        v-model="inventorySlug"
        name="inventory"
        :options="options"
        :nullable="false"
        :label="t('labels.hangarPledgeItems.inventory')"
        data-test="add-to-inventory-select"
      />

      <p class="add-to-inventory__text">
        {{ t("texts.hangarPledgeItems.addToInventory") }}
      </p>
      <ul class="add-to-inventory__items" data-test="add-to-inventory-items">
        <li v-for="item in toAdd.slice(0, LISTED)" :key="item.id">
          {{ item.name }}
          <span v-if="item.quantity > 1" class="add-to-inventory__quantity">
            × {{ item.quantity }}
          </span>
        </li>
        <li v-if="toAdd.length > LISTED" class="add-to-inventory__more">
          {{
            t("labels.hangarPledgeItems.andMore", {
              count: toAdd.length - LISTED,
            })
          }}
        </li>
      </ul>

      <p
        v-if="alreadyAdded.length"
        class="add-to-inventory__note"
        data-test="add-to-inventory-skipped"
      >
        {{
          t("texts.hangarPledgeItems.alreadyInInventory", {
            count: alreadyAdded.length,
          })
        }}
      </p>
    </form>

    <div
      v-else-if="!isLoading"
      class="add-to-inventory"
      data-test="add-to-inventory-none"
    >
      <p class="add-to-inventory__text">
        {{ t("texts.hangarPledgeItems.noInventories") }}
      </p>
      <Btn :to="{ name: 'hangar-inventories' }">
        {{ t("actions.hangarPledgeItems.createInventory") }}
      </Btn>
    </div>

    <template #footer>
      <Btn
        v-if="options.length"
        :type="BtnTypesEnum.SUBMIT"
        form="add-to-inventory-form"
        :disabled="!toAdd.length || !inventorySlug"
        :loading="mutation.isPending.value"
        data-test="add-to-inventory-submit"
      >
        {{ t("actions.hangarPledgeItems.addCount", { count: toAdd.length }) }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.add-to-inventory {
  display: flex;
  flex-direction: column;
  gap: 14px;
}

.add-to-inventory__text,
.add-to-inventory__note {
  margin: 0;
}

.add-to-inventory__note {
  color: var(--color-text-dim, #959595);
  font-size: 14px;
}

.add-to-inventory__items {
  display: flex;
  flex-direction: column;
  gap: 6px;
  margin: 0;
  padding: 10px 14px;
  list-style: none;
  border: 1px solid var(--color-edge-soft, rgb(122 130 136 / 0.28));
  border-radius: var(--radius-surface-slim, 12px);
}

.add-to-inventory__quantity,
.add-to-inventory__more {
  color: var(--color-text-dim, #959595);
  font-variant-numeric: tabular-nums;
}
</style>
