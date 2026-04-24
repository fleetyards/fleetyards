<script lang="ts">
export default {
  name: "ToolsCargoGridsPage",
};
</script>

<script lang="ts" setup>
import { ComponentExposed } from "vue-component-type-helpers";
import Heading from "@/shared/components/base/Heading/index.vue";
import CargoGridViewer from "@/frontend/components/CargoGridViewer/index.vue";
import {
  SHIP_COLORS,
  type ShipEntry,
} from "@/frontend/components/CargoGridViewer/constants";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FilterGroup, {
  type FilterGroupParams,
  type ValueType,
} from "@/shared/components/base/FilterGroup/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import {
  models as fetchModels,
  ModelProductionStatusEnum,
  type Model,
  type ModelQuery,
  type Models,
} from "@/services/fyApi";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import type { ContainerRequest } from "@/frontend/components/CargoGridViewer/constants";
import { useSessionStore } from "@/frontend/stores/session";
import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { useCargoGridShip } from "@/frontend/composables/useCargoGridShip";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const sessionStore = useSessionStore();
const { displayConfirm } = useAppNotifications();

const hangarOnly = ref(false);

const containerFilterActive = ref(false);

const CONTAINER_SIZES = [1, 2, 4, 8, 16, 24, 32] as const;

const MAX_SHIPS = 4;

const modelFilterGroup = ref<ComponentExposed<typeof FilterGroup>>();

// Parse initial slugs from URL (backward compat: ?ship= or new ?ships=)
const parseInitialSlugs = (): string[] => {
  if (route.query.ships) {
    return (route.query.ships as string).split(",").filter(Boolean);
  }
  if (route.query.ship) {
    return [route.query.ship as string];
  }
  return [];
};

const selectedSlugs = ref<string[]>(parseInitialSlugs());

// Pre-allocate composable slots for each possible ship
const shipSlots = Array.from({ length: MAX_SHIPS }, (_, i) => {
  const slug = computed(() => selectedSlugs.value[i]);
  return useCargoGridShip(slug);
});

// Parse and apply initial modules from URL
const applyInitialModules = () => {
  for (const key of Object.keys(route.query)) {
    if (key.startsWith("modules.")) {
      const slug = key.slice("modules.".length);
      const val = route.query[key] as string;
      if (val) {
        const mods = val.split(",").filter(Boolean);
        const idx = selectedSlugs.value.indexOf(slug);
        if (idx >= 0) {
          shipSlots[idx].setModuleSlugs(mods);
        }
      }
    }
  }
  // Backward compat: ?modules= applies to single ship
  if (
    route.query.modules &&
    selectedSlugs.value.length === 1 &&
    selectedSlugs.value[0]
  ) {
    const mods = (route.query.modules as string).split(",").filter(Boolean);
    shipSlots[0].setModuleSlugs(mods);
  }
};
applyInitialModules();

// Build ships array for the unified viewer
const ships = computed<ShipEntry[]>(() => {
  return selectedSlugs.value
    .map((_slug, idx) => {
      const slot = shipSlots[idx];
      const model = slot.model.value;
      if (!model) return null;
      const holds = slot.combinedCargoHolds.value;
      if (!holds.length) return null;
      return {
        name: model.name,
        cargoHolds: holds,
        color: SHIP_COLORS[idx % SHIP_COLORS.length],
      };
    })
    .filter((s): s is ShipEntry => s !== null);
});

// Single-ship mode: use first slot's cargo holds directly
const singleShipCargoHolds = computed(() => {
  if (selectedSlugs.value.length !== 1) return [];
  return shipSlots[0].combinedCargoHolds.value;
});

// Container requests: how many of each size the user wants to load
const containerRequests = ref<Record<number, number>>(
  Object.fromEntries(CONTAINER_SIZES.map((s) => [s, 0])),
);

const hasContainerRequests = computed(() =>
  Object.values(containerRequests.value).some((v) => Number(v) > 0),
);

const requestedContainers = computed<ContainerRequest[]>(() => {
  return CONTAINER_SIZES.filter(
    (s) => Number(containerRequests.value[s]) > 0,
  ).map((s) => ({
    size: s,
    quantity: Number(containerRequests.value[s]),
  }));
});

const clearContainers = () => {
  containerFilterActive.value = false;
  for (const size of CONTAINER_SIZES) {
    containerRequests.value[size] = 0;
  }
};

// Model filter that only shows flight-ready ships with cargo grids
const fetchCargoModels = async (params: FilterGroupParams<Model>) => {
  const q: ModelQuery = {
    withCargoGrids: true,
    productionStatusIn: [ModelProductionStatusEnum.FLIGHT_READY],
  };

  if (params.search) {
    q.nameCont = params.search;
  }

  if (params.missing && !params.search) {
    q.slugEq = params.missing as string;
  }

  if (hangarOnly.value) {
    q.inHangar = true;
  }

  const containerFit: Record<string, number> = {};
  if (containerFilterActive.value && hasContainerRequests.value) {
    for (const size of CONTAINER_SIZES) {
      const qty = Number(containerRequests.value[size]);
      if (qty > 0) {
        containerFit[String(size)] = qty;
      }
    }
  }

  return fetchModels({
    page: String(params.page || 1),
    q,
    containerFit,
  });
};

const formatModels = (response: Models) => {
  return response.items.map((model) => ({
    label: model.name,
    value: model.slug,
    object: model,
  }));
};

const containerFilterVersion = ref(0);

const filterKey = computed(
  () => `cargo-grid-model-${hangarOnly.value}-${containerFilterVersion.value}`,
);

const selectDisabled = computed(() => selectedSlugs.value.length >= MAX_SHIPS);

// URL sync
const syncUrl = () => {
  const query: Record<string, string> = {};
  const slugs = selectedSlugs.value;

  if (slugs.length === 1) {
    query.ship = slugs[0];
  } else if (slugs.length > 1) {
    query.ships = slugs.join(",");
  }

  // Per-ship modules
  for (let i = 0; i < slugs.length; i++) {
    const slug = slugs[i];
    const mods = [...shipSlots[i].selectedModuleSlugs.value];
    if (mods.length) {
      query[`modules.${slug}`] = mods.join(",");
    }
  }

  void router.replace({ query });
};

// Ship management
const handleShipSelect = (value: ValueType<Model> | undefined) => {
  const slug = value as string;
  if (!slug) return;

  // Prevent duplicates and enforce max
  if (
    selectedSlugs.value.includes(slug) ||
    selectedSlugs.value.length >= MAX_SHIPS
  ) {
    modelFilterGroup.value?.clear();
    return;
  }

  selectedSlugs.value = [...selectedSlugs.value, slug];
  modelFilterGroup.value?.clear();
  syncUrl();
};

const removeShip = (index: number) => {
  const next = [...selectedSlugs.value];
  next.splice(index, 1);
  selectedSlugs.value = next;
  syncUrl();
};

const handleToggleModule = (slotIndex: number, moduleSlug: string) => {
  shipSlots[slotIndex].toggleModule(moduleSlug);
  syncUrl();
};

const handleFillGreedy = (slotIndex: number) => {
  const counts = shipSlots[slotIndex].getGreedyFillCounts();
  for (const size of CONTAINER_SIZES) {
    containerRequests.value[size] = counts[size] || 0;
  }
};

const applyContainerFilter = () => {
  containerFilterActive.value = true;
  containerFilterVersion.value++;
  selectedSlugs.value = [];
  syncUrl();
};

const toggleHangarOnly = () => {
  hangarOnly.value = !hangarOnly.value;
  containerFilterVersion.value++;
  selectedSlugs.value = [];
  syncUrl();
};

const doResetFilters = () => {
  hangarOnly.value = false;
  containerFilterActive.value = false;
  clearContainers();
  selectedSlugs.value = [];
  syncUrl();
};

const resetFilters = () => {
  displayConfirm({
    text: t("messages.cargoGridViewer.confirmReset"),
    onConfirm: doResetFilters,
  });
};
</script>

<template>
  <FeatureGuard feature="tools_cargo_grids">
    <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

    <div class="row toolbar">
      <div class="col-12">
        <div class="ship-selector-row" data-test="ship-entries">
          <FilterGroup
            ref="modelFilterGroup"
            :key="filterKey"
            :label="t('labels.selectModel')"
            :search-label="t('labels.findModel')"
            :query-fn="fetchCargoModels"
            :query-response-formatter="formatModels"
            name="cargo-grid-model"
            :paginated="true"
            :searchable="true"
            :multiple="false"
            :disabled="selectDisabled"
            no-label
            inline
            @update:model-value="handleShipSelect"
          />
          <div
            v-for="(slug, idx) in selectedSlugs"
            :key="slug"
            class="ship-entry"
            :data-test="`ship-entry-${idx}`"
          >
            <span
              class="ship-entry__name"
              :style="{
                color: SHIP_COLORS[idx % SHIP_COLORS.length],
              }"
            >
              {{ shipSlots[idx].model.value?.name || slug }}
            </span>
            <template v-if="shipSlots[idx].modulesWithCargo.value.length">
              <Btn
                v-for="mod in shipSlots[idx].modulesWithCargo.value"
                :key="mod.id"
                :size="BtnSizesEnum.SMALL"
                :active="shipSlots[idx].selectedModuleSlugs.value.has(mod.slug)"
                inline
                @click="handleToggleModule(idx, mod.slug)"
              >
                {{ mod.name }}
              </Btn>
            </template>
            <Btn
              v-if="shipSlots[idx].model.value?.cargoHolds?.length"
              :size="BtnSizesEnum.SMALL"
              inline
              @click="handleFillGreedy(idx)"
            >
              {{ t("labels.cargoGridViewer.autoFillShip") }}
            </Btn>
            <Btn
              v-tooltip="t('actions.remove')"
              :size="BtnSizesEnum.SMALL"
              :data-test="`remove-ship-${idx}`"
              inline
              @click="removeShip(idx)"
            >
              <i class="fa-light fa-times" />
            </Btn>
          </div>
          <Btn
            v-if="sessionStore.isAuthenticated"
            :size="BtnSizesEnum.SMALL"
            :active="hangarOnly"
            inline
            @click="toggleHangarOnly"
          >
            {{ t("labels.cargoGridViewer.myHangar") }}
          </Btn>
          <Btn
            v-if="selectedSlugs.length > 0"
            v-tooltip="t('actions.reset')"
            :size="BtnSizesEnum.SMALL"
            data-test="reset-filters"
            inline
            @click="resetFilters"
          >
            <i class="fa-light fa-undo" />
          </Btn>
        </div>

        <div class="container-fields">
          <div
            v-for="size in CONTAINER_SIZES"
            :key="size"
            style="width: 5rem; flex-shrink: 0"
            class="container-field"
            :data-test="`container-field-${size}`"
          >
            <FormInput
              v-model.number="containerRequests[size]"
              :name="`container-${size}`"
              :label="`${size} SCU`"
              :type="InputTypesEnum.NUMBER"
              :min="0"
              :step="1"
              :alignment="InputAlignmentsEnum.RIGHT"
            />
          </div>
          <div class="container-fields__actions">
            <Btn
              v-if="hasContainerRequests"
              :size="BtnSizesEnum.SMALL"
              inline
              @click="applyContainerFilter"
            >
              {{ t("labels.cargoGridViewer.filterShips") }}
            </Btn>
            <Btn
              v-if="hasContainerRequests"
              :size="BtnSizesEnum.SMALL"
              inline
              @click="clearContainers"
            >
              {{ t("actions.clear") }}
            </Btn>
          </div>
        </div>
      </div>
    </div>

    <!-- Unified cargo grid viewer -->
    <div v-if="ships.length" class="row">
      <div class="col-12">
        <CargoGridViewer
          :cargo-holds="singleShipCargoHolds"
          :ships="ships.length > 1 ? ships : []"
          :container-requests="requestedContainers"
        />
      </div>
    </div>

    <!-- Preview mode: containers without ship -->
    <template v-else-if="hasContainerRequests">
      <div class="row">
        <div class="col-12">
          <CargoGridViewer
            :cargo-holds="[]"
            :container-requests="requestedContainers"
          />
        </div>
      </div>
    </template>
  </FeatureGuard>
</template>

<style lang="scss" scoped>
@import "./cargo-grids.scss";
</style>
