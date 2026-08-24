<script lang="ts">
export default {
  name: "AdminComponentEditPricesPage",
};
</script>

<script lang="ts" setup>
import { useI18n } from "@/shared/composables/useI18n";
import Heading from "@/shared/components/base/Heading/index.vue";
import { type Component } from "@/services/fyAdminApi";
import ItemPricesList from "@/admin/components/ItemPrices/List.vue";

type Props = {
  component: Component;
};

const props = defineProps<Props>();

const { t } = useI18n();

const itemPricesList = ref<{
  creating: boolean;
  startCreate: () => void;
} | null>(null);
</script>

<template>
  <div class="flex items-center justify-between mb-4">
    <Heading hero>{{
      t("headlines.admin.components.edit.itemPrices")
    }}</Heading>
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
    :item-id="props.component.id"
    item-type="Component"
  />
</template>
