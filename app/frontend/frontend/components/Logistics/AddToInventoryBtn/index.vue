<script lang="ts">
export default {
  name: "LogisticsAddToInventoryBtn",
};
</script>

<script lang="ts" setup>
import { storeToRefs } from "pinia";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useSessionStore } from "@/frontend/stores/session";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { catalogueSelection } from "@/frontend/components/Logistics/selection";
import { type ItemPickerEntry } from "@/frontend/components/Logistics/types";
import { FeatureFlagName } from "@/services/fyApi";

type Props = {
  entry: ItemPickerEntry;
};

const props = defineProps<Props>();

const { t } = useI18n();
const comlink = useComlink();
const { isAuthenticated } = storeToRefs(useSessionStore());
const { isFeatureEnabled } = useFeatures();

// A retired record is kept for the entries that already point at it; the
// pickers no longer offer it for new ones, and neither does its page.
const visible = computed(
  () =>
    isAuthenticated.value &&
    (isFeatureEnabled(FeatureFlagName.HANGAR_INVENTORIES) ||
      isFeatureEnabled(FeatureFlagName.FLEET_LOGISTICS)) &&
    !props.entry.record.retired,
);

const open = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Logistics/InventoryItemModal/index.vue"),
    props: { item: catalogueSelection(props.entry) },
  });
};
</script>

<template>
  <Teleport v-if="visible" to="#header-right">
    <Btn :size="BtnSizesEnum.MD" data-test="add-to-inventory" @click="open">
      <i class="fa-duotone fa-box-open" aria-hidden="true" />
      <span>{{ t("actions.logistics.addToInventory") }}</span>
    </Btn>
  </Teleport>
</template>
