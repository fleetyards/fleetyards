<script lang="ts">
export default {
  name: "FleetLogisticsInventoryPanel",
};
</script>

<script lang="ts" setup>
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { type Fleet, type FleetInventory } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import { PanelShadowsEnum } from "@/shared/components/base/Panel/types";
import fallbackImage1 from "@/images/inventories/placeholder-1.webp";
import fallbackImage2 from "@/images/inventories/placeholder-2.jpg";

const fallbackImages = [fallbackImage1, fallbackImage2];

type Props = {
  fleet: Fleet;
  inventory: FleetInventory;
  fleetSlug: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  editable: false,
});

const { t } = useI18n();
const comlink = useComlink();

const location = computed(
  () => (props.inventory as unknown as { location?: string }).location,
);

const totalScu = computed(
  () => (props.inventory as unknown as { totalScu?: number }).totalScu ?? 0,
);

const totalUnits = computed(
  () => (props.inventory as unknown as { totalUnits?: number }).totalUnits ?? 0,
);

const fallbackIndex = computed(() => {
  let hash = 0;
  for (const ch of props.inventory.name) {
    hash = (hash << 5) - hash + ch.charCodeAt(0);
  }
  return Math.abs(hash) % fallbackImages.length;
});

const image = computed(() => {
  const img = (props.inventory as unknown as { image?: { mediumUrl?: string } })
    .image;

  return img?.mediumUrl || fallbackImages[fallbackIndex.value];
});

const openEditModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Fleets/Logistics/InventoryModal/index.vue"),
    props: {
      fleet: props.fleet,
      inventory: props.inventory,
    },
  });
};
</script>

<template>
  <Panel
    :bg-image="image"
    :shadow="PanelShadowsEnum.TOP"
    class="inventory-panel"
  >
    <PanelHeading :level="HeadingLevelEnum.H2">
      <template #default>
        <router-link
          :to="{
            name: 'fleet-logistics-inventory',
            params: { slug: fleetSlug, inventory: inventory.slug },
          }"
        >
          {{ inventory.name }}
        </router-link>
      </template>
      <template v-if="location" #subtitle>
        {{ location }}
      </template>
      <template v-if="editable" #actions>
        <Btn
          :variant="BtnVariantsEnum.LINK"
          :inline="true"
          class="inventory-panel-edit"
          @click.prevent="openEditModal"
        >
          <i class="fa-duotone fa-pen" />
        </Btn>
      </template>
    </PanelHeading>
    <PanelBody class="inventory-panel-body" rounded="bottom">
      <div v-if="inventory.manager" class="inventory-panel-manager">
        {{ t("labels.fleets.logistics.managedBy") }}
        {{ inventory.manager.username }}
      </div>
      <div class="inventory-panel-counts">
        <div class="inventory-panel-count">
          <span class="inventory-panel-count-number">
            {{ inventory.itemCount }}
          </span>
          <span class="inventory-panel-count-label">
            {{ t("labels.fleets.logistics.items") }}
          </span>
        </div>
        <template v-if="totalScu > 0 || totalUnits > 0">
          <span class="inventory-panel-count-separator">|</span>
          <span v-if="totalScu > 0" class="inventory-panel-count-unit">
            {{ totalScu }} SCU
          </span>
          <span
            v-if="totalScu > 0 && totalUnits > 0"
            class="inventory-panel-count-separator"
            >|</span
          >
          <span v-if="totalUnits > 0" class="inventory-panel-count-unit">
            {{ totalUnits }} Units
          </span>
        </template>
      </div>
    </PanelBody>
  </Panel>
</template>

<style lang="scss" scoped>
.inventory-panel {
  .inventory-panel-body {
    flex: 1;
    display: flex;
    align-items: flex-end;
    min-height: 60px;
  }

  &-edit {
    font-size: 18px;

    > :first-child {
      font-size: 18px;
    }
  }

  &-manager {
    position: absolute;
    bottom: 10px;
    right: 0;
    padding: 4px 10px;
    background-color: $primary;
    border-radius: 10px 0 0 10px;
    font-size: 0.85em;
    display: flex;
    align-items: center;
    gap: 4px;
    color: #fff;
  }

  &-counts {
    display: flex;
    align-items: baseline;
    gap: 8px;
    text-shadow:
      0 1px 4px rgba(0, 0, 0, 0.8),
      0 0 12px rgba(0, 0, 0, 0.6);
  }

  &-count {
    display: flex;
    align-items: baseline;
    gap: 6px;
  }

  &-count-number {
    font-size: 2em;
    font-weight: 700;
    line-height: 1;
    color: #fff;
  }

  &-count-label {
    font-size: 0.8em;
    color: $gray-light;
    text-transform: uppercase;
    letter-spacing: 0.05em;
  }

  &-count-separator {
    color: $gray-light;
    opacity: 0.4;
  }

  &-count-unit {
    font-size: 0.85em;
    color: $gray-light;
  }
}
</style>
