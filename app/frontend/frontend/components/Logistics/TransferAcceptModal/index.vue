<script lang="ts">
export default {
  name: "LogisticsTransferAcceptModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import type {
  FilterOption,
  HangarInventory,
  InventoryTransfer,
} from "@/services/fyApi";

type Props = {
  transfer: InventoryTransfer;
  inventories: HangarInventory[];
  onAccept: (inventoryId: string) => Promise<unknown>;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();

const submitting = ref(false);
const inventoryId = ref<string | undefined>(props.inventories[0]?.id);

const options = computed<FilterOption[]>(() =>
  props.inventories.map((inventory) => ({
    value: inventory.id,
    label: inventory.name,
  })),
);

const onSubmit = async () => {
  if (!inventoryId.value) return;

  submitting.value = true;

  try {
    await props.onAccept(inventoryId.value);
    comlink.emit("close-modal");
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal :title="t('headlines.logistics.acceptTransfer')">
    <form id="accept-transfer-form" @submit.prevent="onSubmit">
      <BaseSelect
        v-model="inventoryId"
        name="inventory"
        :options="options"
        :label="t('labels.logistics.acceptInto')"
        data-test="accept-inventory"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LG"
          data-test="accept-submit"
          @click="onSubmit"
        >
          {{ t("actions.logistics.acceptTransfer") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
