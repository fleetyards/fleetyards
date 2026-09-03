<script lang="ts">
export default {
  name: "ToolsCargoGridsPage",
};
</script>

<script lang="ts" setup>
import Heading from "@/shared/components/base/Heading/index.vue";
import CargoGridViewer from "@/frontend/components/CargoGridViewer/index.vue";
import {
  SHIP_COLORS,
  encodeContainerCounts,
  parseContainerCounts,
  type ContainerRequest,
  type ShipEntry,
} from "@/frontend/components/CargoGridViewer/constants";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import ViewImage from "@/shared/components/ViewImage/index.vue";
import { LazyImageVariantsEnum } from "@/shared/components/LazyImage/types";
import { useI18n } from "@/shared/composables/useI18n";
import { ContainerSizeEnum, type ContainerFitQuery } from "@/services/fyApi";
import {
  InputTypesEnum,
  InputAlignmentsEnum,
} from "@/shared/components/base/FormInput/types";

import FeatureGuard from "@/frontend/components/FeatureGuard.vue";
import { FeatureFlagName } from "@/services/fyApi";
import { useCargoGridShip } from "@/frontend/composables/useCargoGridShip";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useMobile } from "@/shared/composables/useMobile";

const { t } = useI18n();

const route = useRoute();
const router = useRouter();

const { displayConfirm } = useAppNotifications();

const comlink = useComlink();

const mobile = useMobile();

// Derived from the schema rather than repeated: ContainerSizeEnum is generated
// from CargoHoldContainerCapacity::CONTAINER_SIZES, so adding a size on the
// Ruby side reaches this page without an edit.
const CONTAINER_SIZE_KEYS = Object.values(ContainerSizeEnum);

const CONTAINER_SIZES = CONTAINER_SIZE_KEYS.map(Number);

const MAX_SHIPS = 4;

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

const hasModules = computed(() =>
  selectedSlugs.value.some(
    (_, idx) => shipSlots[idx].modulesWithCargo.value.length > 0,
  ),
);

// Build ships array for the unified viewer
const ships = computed(() => {
  const result: ShipEntry[] = [];
  for (let idx = 0; idx < selectedSlugs.value.length; idx++) {
    const slot = shipSlots[idx];
    const model = slot.model.value;
    if (!model) continue;
    const holds = slot.combinedCargoHolds.value;
    if (!holds.length) continue;
    result.push({
      name: model.name,
      cargoHolds: holds,
      color: SHIP_COLORS[idx % SHIP_COLORS.length],
      image: slot.angledImage.value,
      route: slot.shipRoute.value,
    });
  }
  return result;
});

// Single-ship mode: use first slot's cargo holds directly
const singleShipCargoHolds = computed(() => {
  if (selectedSlugs.value.length !== 1) return [];
  return shipSlots[0].combinedCargoHolds.value;
});

// Container requests: how many of each size the user wants to load. A link may
// arrive with a load already counted out - a ship inventory sends what it holds.
//
// Sparse rather than zero-filled: an empty counter reads as "none of these",
// where a row of zeroes hides which sizes carry a load.
const containerRequests = ref<Record<number, number>>({
  ...parseContainerCounts(route.query.containers),
});

const containerCount = (size: number) =>
  Number(containerRequests.value[size]) || 0;

const hasContainerRequests = computed(() =>
  Object.values(containerRequests.value).some((v) => Number(v) > 0),
);

const requestedContainers = computed<ContainerRequest[]>(() => {
  return CONTAINER_SIZES.filter((s) => containerCount(s) > 0).map((s) => ({
    size: s,
    quantity: containerCount(s),
  }));
});

const clearContainers = () => {
  containerRequests.value = {};
};

// The load typed into the form, in the shape the picker's query takes. Iterated
// over the enum rather than CONTAINER_SIZES: its values are the literal keys
// ContainerFitQuery declares, so this indexes without a cast.
const containerFit = computed<ContainerFitQuery>(() => {
  const fit: ContainerFitQuery = {};

  for (const size of CONTAINER_SIZE_KEYS) {
    const quantity = containerCount(Number(size));

    if (quantity > 0) {
      fit[size] = quantity;
    }
  }

  return fit;
});

const full = computed(() => selectedSlugs.value.length >= MAX_SHIPS);

// URL sync
const syncUrl = () => {
  const query: Record<string, string> = {};
  const slugs = selectedSlugs.value;

  if (slugs.length === 1) {
    query.ship = slugs[0];
  } else if (slugs.length > 1) {
    query.ships = slugs.join(",");
  }

  const containers = encodeContainerCounts(containerRequests.value);
  if (containers) {
    query.containers = containers;
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

// The counts are typed into the form rather than routed through an action, so
// the URL follows them instead of being rewritten only when a ship changes.
watch(containerRequests, () => syncUrl(), { deep: true });

/**
 * Opens the shared ship picker, carrying the load typed into the form over as its
 * container filter - the ships worth offering are the ones that can take it. The
 * filter is editable in the modal, and widening it there leaves the page's counts
 * alone.
 */
const openPicker = () => {
  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/CargoGrids/Models/PickerModal/index.vue"),
    props: {
      taken: selectedSlugs.value,
      max: MAX_SHIPS,
      containerFit: containerFit.value,
    },
    wide: true,
  });
};

// The picker sizes its own cap from what was free when it opened, so the ceiling
// and the duplicates are checked again here - a link opened in the meantime, or a
// ship removed behind the modal, moves both.
const addShips = (slugs: string[]) => {
  const next = [...selectedSlugs.value];

  for (const slug of slugs) {
    if (next.length >= MAX_SHIPS || next.includes(slug)) continue;

    next.push(slug);
  }

  selectedSlugs.value = next;
  syncUrl();
};

const offModelsPicked = ref<() => void>();

onMounted(() => {
  offModelsPicked.value = comlink.on("cargo-grids-models-picked", addShips);
});

onUnmounted(() => {
  offModelsPicked.value?.();
});

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
  const next: Record<number, number> = {};

  for (const size of CONTAINER_SIZES) {
    if (counts[size] > 0) {
      next[size] = counts[size];
    }
  }

  containerRequests.value = next;
};

const doResetFilters = () => {
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
  <FeatureGuard :feature="FeatureFlagName.TOOLS_CARGO_GRIDS">
    <div class="cargo-grids-page">
      <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

      <div class="row toolbar">
        <div class="col-12 col-lg-8">
          <div class="ship-selector-row" data-test="ship-entries">
            <!-- The tooltip hangs on the wrapper, not the button: a disabled
                 button dispatches no pointer events, so the one case that has
                 something to say could never say it. -->
            <div
              v-tooltip="
                full ? t('labels.cargoGridViewer.enoughShips') : undefined
              "
            >
              <Btn
                :disabled="full"
                data-test="cargo-grid-add-ships"
                @click="openPicker()"
              >
                <i class="fa-light fa-plus" />
                {{ t("labels.cargoGridViewer.addShip") }}
              </Btn>
            </div>
            <Btn
              v-if="selectedSlugs.length > 0"
              v-tooltip="t('actions.reset')"
              data-test="reset-filters"
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
                :class="{
                  'container-field--set': containerCount(size) > 0,
                }"
                :name="`container-${size}`"
                :label="`${size} SCU`"
                :type="InputTypesEnum.NUMBER"
                :min="0"
                :step="1"
                :alignment="InputAlignmentsEnum.RIGHT"
              />
            </div>
            <div class="container-fields__actions">
              <Btn v-if="hasContainerRequests" @click="clearContainers">
                {{ t("actions.clear") }}
              </Btn>
            </div>
          </div>

          <div v-if="hasModules" class="ship-modules">
            <template v-for="(slug, idx) in selectedSlugs" :key="slug">
              <template v-if="shipSlots[idx].modulesWithCargo.value.length">
                <span
                  class="ship-entry__name"
                  :style="{
                    color: SHIP_COLORS[idx % SHIP_COLORS.length],
                  }"
                >
                  {{ shipSlots[idx].model.value?.name }}
                </span>
                <Btn
                  v-for="mod in shipSlots[idx].modulesWithCargo.value"
                  :key="mod.id"
                  :active="
                    shipSlots[idx].selectedModuleSlugs.value.has(mod.slug)
                  "
                  @click="handleToggleModule(idx, mod.slug)"
                >
                  {{ mod.name }}
                </Btn>
              </template>
            </template>
          </div>
        </div>
        <div v-if="selectedSlugs.length && !mobile" class="col-12 col-lg-4">
          <div class="ship-infos">
            <router-link
              v-for="(slug, idx) in selectedSlugs"
              :key="slug"
              :to="shipSlots[idx].shipRoute.value || {}"
              class="ship-info"
            >
              <ViewImage
                v-if="shipSlots[idx].angledImage.value"
                :image="shipSlots[idx].angledImage.value"
                size="medium"
                :alt="shipSlots[idx].model.value?.name || slug"
                :variant="LazyImageVariantsEnum.WIDE"
                transparent
                without-fallback
                class="ship-info__image"
              />
              <span
                class="ship-info__name"
                :style="{
                  color: SHIP_COLORS[idx % SHIP_COLORS.length],
                }"
              >
                {{ shipSlots[idx].model.value?.name || slug }}
              </span>
            </router-link>
          </div>
        </div>
      </div>

      <!-- Unified cargo grid viewer -->
      <div v-if="ships.length" class="row cargo-grids-page__viewer">
        <div class="col-12">
          <CargoGridViewer
            :cargo-holds="singleShipCargoHolds"
            :ships="ships"
            :container-requests="requestedContainers"
            @auto-fill="handleFillGreedy"
            @remove-ship="removeShip"
          />
        </div>
      </div>

      <!-- Preview mode: containers without ship -->
      <div
        v-else-if="hasContainerRequests"
        class="row cargo-grids-page__viewer"
      >
        <div class="col-12">
          <CargoGridViewer
            :cargo-holds="[]"
            :container-requests="requestedContainers"
          />
        </div>
      </div>
    </div>
  </FeatureGuard>
</template>

<style lang="scss" scoped>
@import "./cargo-grids.scss";
</style>
