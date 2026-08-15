<script lang="ts">
export default {
  name: "InventoryPanel",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelHeading from "@/shared/components/base/Panel/Heading/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import type { InventoryPanelRecord } from "@/frontend/types/logistics";
import fallbackImage1 from "@/images/inventories/placeholder-1.webp";
import fallbackImage2 from "@/images/inventories/placeholder-2.jpg";

const fallbackImages = [fallbackImage1, fallbackImage2];

type Props = {
  inventory: InventoryPanelRecord;
  to: RouteLocationRaw;
  managedBy?: string;
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  managedBy: undefined,
  editable: false,
});

const emit = defineEmits<{ edit: [] }>();

const { t } = useI18n();

const totalScu = computed(() => props.inventory.totalScu ?? 0);

const totalUnits = computed(() => props.inventory.totalUnits ?? 0);

const fallbackIndex = computed(() => {
  let hash = 0;
  for (const ch of props.inventory.name) {
    hash = (hash << 5) - hash + ch.charCodeAt(0);
  }
  return Math.abs(hash) % fallbackImages.length;
});

const image = computed(
  () => props.inventory.image?.mediumUrl || fallbackImages[fallbackIndex.value],
);
</script>

<template>
  <Panel :bg-image="image" class="inventory-panel">
    <PanelHeading shadow="top" :level="HeadingLevelEnum.H2">
      <template #default>
        <router-link :to="to">
          {{ inventory.name }}
        </router-link>
      </template>
      <template v-if="inventory.location" #subtitle>
        {{ inventory.location }}
      </template>
      <template v-if="editable" #actions>
        <Btn
          :variant="BtnVariantsEnum.BARE"
          class="inventory-panel-edit"
          @click.prevent="emit('edit')"
        >
          <i class="fa-duotone fa-pen" />
        </Btn>
      </template>
    </PanelHeading>
    <PanelBody class="inventory-panel-body" rounded="bottom">
      <div v-if="managedBy" class="inventory-panel-manager">
        {{ t("labels.logistics.managedBy") }}
        {{ managedBy }}
      </div>
      <div class="inventory-panel-counts">
        <div class="inventory-panel-count">
          <span class="inventory-panel-count-number">
            {{ inventory.itemCount }}
          </span>
          <span class="inventory-panel-count-label">
            {{ t("labels.logistics.items") }}
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
