<script lang="ts">
export default {
  name: "AdminUserInventoryItemPage",
};
</script>

<script lang="ts" setup>
import AsyncData from "@/shared/components/AsyncData.vue";
import InventoryItemDetail from "@/admin/components/InventoryItemDetail/index.vue";
import {
  type User,
  useUserInventoryItem as useUserInventoryItemQuery,
} from "@/services/fyAdminApi";

type Props = {
  user: User;
};

const props = defineProps<Props>();

const route = useRoute();

const inventoryId = computed(() => route.params.inventoryId as string);
const itemId = computed(() => route.params.itemId as string);

const { data: item, ...asyncStatus } = useUserInventoryItemQuery(
  props.user.id!,
  inventoryId,
  itemId,
);
</script>

<template>
  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <InventoryItemDetail v-if="item" :item="item" item-type="InventoryItem" />
    </template>
  </AsyncData>
</template>
