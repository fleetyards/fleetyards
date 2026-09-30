<script lang="ts">
export default {
  name: "CatalogueItemLink",
};
</script>

<script lang="ts" setup>
import StatsPopover from "@/shared/components/StatsPopover/index.vue";
import ComponentStatsCard from "@/frontend/components/StatsCard/Component/index.vue";
import EquipmentStatsCard from "@/frontend/components/StatsCard/Equipment/index.vue";
import { catalogueItemRoute } from "@/frontend/utils/catalogueItemRoute";
import {
  useComponent as useComponentQuery,
  useEquipmentItem as useEquipmentItemQuery,
} from "@/services/fyApi";

type CatalogueItem = {
  type?: string | null;
  slug?: string | null;
  name?: string | null;
  listed?: boolean;
};

type Props = {
  item: CatalogueItem;
};

const props = defineProps<Props>();

const route = computed(() => catalogueItemRoute(props.item));

const slug = computed(() => props.item.slug || "");

const isComponent = computed(() => props.item.type === "Component");
const isEquipment = computed(() => props.item.type === "Equipment");

// A reference names its record by slug and nothing more, so the card is
// fetched the first time it is opened -- never for every link on a page -- and
// stays enabled afterwards so the query cache answers every later open.
const requested = ref(false);

const { data: component, isPending: componentPending } = useComponentQuery(
  slug,
  {
    query: {
      enabled: computed(
        () => requested.value && isComponent.value && !!slug.value,
      ),
    },
  },
);

const { data: equipment, isPending: equipmentPending } = useEquipmentItemQuery(
  slug,
  {
    query: {
      enabled: computed(
        () => requested.value && isEquipment.value && !!slug.value,
      ),
    },
  },
);

const hasCard = computed(
  () => !!route.value && (isComponent.value || isEquipment.value),
);
</script>

<template>
  <StatsPopover
    v-if="hasCard"
    :label="item.name || ''"
    @open="requested = true"
  >
    <router-link :to="route!">
      <slot>{{ item.name }}</slot>
    </router-link>

    <template #content="{ close }">
      <ComponentStatsCard
        v-if="isComponent"
        :component="component"
        :loading="componentPending"
        @navigate="close"
      />
      <EquipmentStatsCard
        v-else
        :equipment="equipment"
        :loading="equipmentPending"
        @navigate="close"
      />
    </template>
  </StatsPopover>

  <router-link v-else-if="route" :to="route">
    <slot>{{ item.name }}</slot>
  </router-link>

  <template v-else>
    <slot>{{ item.name }}</slot>
  </template>
</template>
