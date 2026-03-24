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
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";

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
  <div class="d-flex align-items-center justify-content-between">
    <Heading hero>{{ t("headlines.admin.components.edit.itemPrices") }}</Heading>
    <Btn
      :size="BtnSizesEnum.SMALL"
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
