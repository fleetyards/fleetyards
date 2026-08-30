<script lang="ts">
export default {
  name: "AdminFleetInventoryItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import InventoryItemDetail from "@/admin/components/InventoryItemDetail/index.vue";
import {
  type Fleet,
  useFleetInventoryItem as useFleetInventoryItemQuery,
} from "@/services/fyAdminApi";

type Props = {
  fleet: Fleet;
};

const props = defineProps<Props>();

const route = useRoute();

const inventoryId = computed(() => route.params.inventoryId as string);
const itemId = computed(() => route.params.itemId as string);

const { data: item, ...asyncStatus } = useFleetInventoryItemQuery(
  props.fleet.id,
  inventoryId,
  itemId,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <InventoryItemDetail
        v-if="item"
        :item="item"
        item-type="FleetInventoryItem"
      />
    </template>
  </AsyncData>
</template>
