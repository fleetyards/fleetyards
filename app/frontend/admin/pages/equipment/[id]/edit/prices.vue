<script lang="ts">
export default {
  name: "AdminEquipmentEditPricesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type Equipment } from "@/services/fyAdminApi";
import ItemPricesList from "@/admin/components/ItemPrices/List.vue";

type Props = {
  equipment: Equipment;
};

const props = defineProps<Props>();

const { t } = useI18n();

const itemPricesList = ref<{
  creating: boolean;
  startCreate: () => void;
} | null>(null);
</script>

<template>
  <div class="flex items-center justify-between">
    <Heading hero>{{ t("headlines.admin.equipment.edit.itemPrices") }}</Heading>
    <Btn
      :disabled="itemPricesList?.creating"
      @click="itemPricesList?.startCreate()"
    >
      <i class="fa-duotone fa-plus" />
      {{ t("actions.add") }}
    </Btn>
  </div>

  <ItemPricesList
    ref="itemPricesList"
    :item-id="props.equipment.id"
    item-type="Equipment"
  />
</template>
