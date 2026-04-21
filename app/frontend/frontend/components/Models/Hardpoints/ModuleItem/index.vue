<script lang="ts">
export default {
  name: "HardpointModuleItem",
};
</script>

<script lang="ts" setup>
import { type ComputedRef } from "vue";
import HardpointItem from "@/frontend/components/Models/Hardpoints/Item/index.vue";
import HardpointSize from "@/frontend/components/Models/Hardpoints/Size/index.vue";
import HardpointComponent from "@/frontend/components/Models/Hardpoints/Component/index.vue";
import HardpointCategory from "@/frontend/components/Models/Hardpoints/Category/index.vue";
import { groupBy, sortBy } from "@/shared/utils/Array";
import {
  type Hardpoint,
  type ModelModule,
  HardpointCategoryEnum,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  hardpoints: Hardpoint[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const modelModules = inject<ComputedRef<ModelModule[]>>(
  "modelModules",
  computed(() => []),
);

const equippedModules = inject<Ref<Record<string, ModelModule | null>>>(
  "equippedModules",
  ref({}),
);

const setEquippedModule = inject<
  (slotId: string, mod: ModelModule | null) => void
>("setEquippedModule", () => {});

const hardpoint = computed(() => props.hardpoints[0]);

const count = computed(() => props.hardpoints.length);

const slotId = computed(() => hardpoint.value.groupKey || hardpoint.value.id);

const SLOT_POSITION_KEYWORDS = ["front", "rear", "bow", "stern"] as const;

const slotPosition = computed(() => {
  const name = (hardpoint.value.name || "").toLowerCase();
  return SLOT_POSITION_KEYWORDS.find((kw) => name.includes(kw)) || null;
});

const compatibleModules = computed(() => {
  const hpName = hardpoint.value.name || "";

  // Prefer slot-based filtering: match modules whose slot matches this hardpoint's name
  const slotFiltered = modelModules.value.filter((m) => m.slot === hpName);
  if (slotFiltered.length > 0) {
    return slotFiltered;
  }

  // Fallback: keyword-based heuristic for modules without slot data
  if (!slotPosition.value || modelModules.value.length <= 1) {
    return modelModules.value;
  }

  const pos = slotPosition.value;
  const filtered = modelModules.value.filter((m) => {
    const moduleName = (m.name || "").toLowerCase();
    const moduleKey = (m.scKey || "").toLowerCase();
    return moduleName.includes(pos) || moduleKey.includes(pos);
  });

  return filtered.length > 0 ? filtered : modelModules.value;
});

const selectedModule = computed(
  () => equippedModules.value[slotId.value] || null,
);

const expanded = ref(false);

const onModuleSelect = (mod: ModelModule | null) => {
  setEquippedModule(slotId.value, mod);
  expanded.value = !!mod;
};

const openModuleModal = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Models/Hardpoints/ModuleItem/Modal/index.vue"),
    props: {
      modules: compatibleModules.value,
      selectedModuleSlug: selectedModule.value?.slug,
      onSelect: onModuleSelect,
    },
  });
};

const toggleExpanded = () => {
  if (selectedModule.value) {
    expanded.value = !expanded.value;
  }
};

const moduleCategories = computed(() => {
  if (!selectedModule.value?.hardpoints?.length) return {};

  const sorted = sortBy<Hardpoint>(selectedModule.value.hardpoints, "category");
  const grouped = groupBy<Hardpoint>(sorted, "category");

  const result: { [key in HardpointCategoryEnum]?: Hardpoint[] } = {};

  Object.keys(grouped).forEach((category) => {
    if (
      category === HardpointCategoryEnum.CONTROLLER ||
      category === HardpointCategoryEnum.UNKNOWN
    ) {
      return;
    }
    result[category as HardpointCategoryEnum] = grouped[category];
  });

  return result;
});

const hasExpandableContent = computed(
  () => Object.keys(moduleCategories.value).length > 0,
);
</script>

<template>
  <HardpointItem :count="count">
    <template #default>
      <HardpointSize :size="hardpoint.maxSize" />
      <HardpointComponent>
        <span
          class="module-select-btn"
          :class="{ 'module-select-btn-active': selectedModule }"
          @click="openModuleModal"
        >
          <i class="fa-duotone fa-puzzle" />
          {{ selectedModule?.name || t("labels.hardpoint.moduleSlotEmpty") }}
        </span>
      </HardpointComponent>
      <button
        v-if="selectedModule && hasExpandableContent"
        class="module-expand-toggle"
        @click="toggleExpanded"
      >
        <i
          class="fa-light"
          :class="expanded ? 'fa-chevron-up' : 'fa-chevron-down'"
        />
      </button>
    </template>
    <template #loadout>
      <div
        v-if="expanded && selectedModule && hasExpandableContent"
        class="module-loadout"
      >
        <HardpointCategory
          v-for="(items, category) in moduleCategories"
          :key="category"
          :hardpoints="items || []"
          :category="category"
        />
      </div>
    </template>
  </HardpointItem>
</template>

<style lang="scss" scoped>
@import "index";
</style>
