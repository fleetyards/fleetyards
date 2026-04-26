<script lang="ts">
export default {
  name: "FleetLogisticsInventoryCard",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import { type Fleet, type FleetInventory } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  fleet: Fleet;
  inventory: FleetInventory;
};

defineProps<Props>();

const { t } = useI18n();
</script>

<template>
  <Btn
    :to="{
      name: 'fleet-logistics-inventory',
      params: { slug: fleet.slug, inventory: inventory.slug },
    }"
    block
    align-start
  >
    <div>
      <h5>{{ inventory.name }}</h5>
      <p v-if="inventory.description" class="text-muted">
        {{ inventory.description }}
      </p>
      <div class="d-flex justify-content-between">
        <span class="text-muted">
          {{ inventory.itemCount }}
          {{ t("labels.fleets.logistics.items") }}
        </span>
        <span v-if="inventory.manager" class="text-muted">
          {{ inventory.manager.username }}
        </span>
      </div>
    </div>
  </Btn>
</template>
