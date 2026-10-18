<script lang="ts">
export default {
  name: "VehicleLoadoutView",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import { useLoadoutProblems } from "@/frontend/composables/useLoadoutProblems";
import LoadoutChanges from "@/frontend/components/Loadout/Changes/index.vue";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";
import { useLoadoutModules } from "@/frontend/composables/useLoadoutModules";
import {
  COMPONENT_TABS,
  slotName,
} from "@/frontend/composables/useComponentFitting";
import { useLoadoutFitting } from "@/frontend/composables/useLoadoutFitting";
import {
  HardpointCategoryEnum,
  type LoadoutSlot,
  ModelProductionStatusEnum,
  type Vehicle,
  type VehicleLoadout,
  type VehicleLoadoutMinimal,
  type VehiclePublic,
  useVehicleLoadoutSlots,
} from "@/services/fyApi";

type Props = {
  vehicle: Vehicle | VehiclePublic;
  loadout?: VehicleLoadout | VehicleLoadoutMinimal;
  // The owner, who gets a way into the editor from here.
  editable?: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  loadout: undefined,
  editable: false,
});

const { t } = useI18n();

const { slotLabel } = useLoadoutSlotLabel();

const model = computed(() => props.vehicle.model);

const { moduleRows, loading: modulesLoading } = useLoadoutModules(
  () => model.value?.slug,
  () => props.loadout,
);

// The parts swapped in or taken out, read off the loadout's slot tree. Only the owner can
// read that tree, so only the owner sees them.
const { data: loadoutSlots, isLoading: slotsLoading } = useVehicleLoadoutSlots(
  () => props.vehicle.id,
  () => props.loadout?.id ?? "",
  { query: { enabled: () => props.editable && !!props.loadout?.id } },
);

// Only the owner can read what the build refuses, as with the slot tree.
const {
  problems,
  reason,
  describe,
  loading: problemsLoading,
} = useLoadoutProblems(
  () => props.vehicle.id,
  () => props.loadout?.id,
  () => props.editable,
);

const refusedAt = computed(
  () => new Map(problems.value.map((problem) => [problem.slotPath, problem])),
);

// Why the build in force refuses what a slot holds, for its badge's tooltip.
const refusedReason = (slotPath: string) => {
  const problem = refusedAt.value.get(slotPath);

  return problem
    ? `${t("labels.vehicleLoadout.refused.badge")}: ${reason(problem)}`
    : undefined;
};

// What the loadout changes on the ship as the game files deliver it, worked out
// by the editor's own diff. The parts in it are known only from the owner's
// slot tree, so a visitor sees what the modules change.
const flightReady = computed(
  () =>
    model.value?.productionStatus === ModelProductionStatusEnum.FLIGHT_READY,
);

const { changesFromStock, loading: fittingLoading } = useLoadoutFitting({
  model,
  loadoutSlots,
  items: () => props.loadout?.items,
  enabled: () => props.editable && flightReady.value,
});

// The figures a reader looks for first, as tiles, and whatever else moved
// after them as a list, kin kept together: damage, defence, cargo, power, then
// what the ship gives away.
const LEAD_FIGURES = [
  "dps",
  "shieldHp",
  "cargo",
  "power",
  "sustainedDps",
  "alpha",
  "missileDamage",
  "shieldRegen",
  "pips",
  "cooling",
  "em",
  "ir",
];
const MAX_TILES = 4;

const leadRank = (key: string) => {
  const rank = LEAD_FIGURES.indexOf(key);

  return rank === -1 ? LEAD_FIGURES.length : rank;
};

const rankedChanges = computed(() =>
  changesFromStock.value
    .map((figure, index) => ({ figure, index }))
    .sort(
      (a, b) =>
        leadRank(a.figure.key) - leadRank(b.figure.key) || a.index - b.index,
    )
    .map(({ figure }) => figure),
);

const keyChanges = computed(() => rankedChanges.value.slice(0, MAX_TILES));

const otherChanges = computed(() => rankedChanges.value.slice(MAX_TILES));

// What is fitted is known once the modules are named and, for the owner, the
// slot tree has arrived; what changed needs the stock ship besides.
const fittedLoading = computed(
  () => modulesLoading.value || slotsLoading.value,
);

const changesLoading = computed(
  () => fittedLoading.value || fittingLoading.value,
);

const loading = computed(() => changesLoading.value || problemsLoading.value);

type ComponentRow = { slotPath: string; label: string; slot: LoadoutSlot };

const swappedIn = (
  slots: LoadoutSlot[],
  rootLabel?: string,
  parentPath?: string,
): ComponentRow[] =>
  slots.flatMap((slot) => {
    const slotPath = parentPath ? `${parentPath}/${slot.name}` : slot.name;
    const label = rootLabel
      ? `${rootLabel} › ${slotName(slot.name)}`
      : slotName(slot.name);
    const own = slot.fitted || slot.emptied ? [{ slotPath, label, slot }] : [];

    return [
      ...own,
      ...swappedIn(slot.slots, rootLabel ?? slotName(slot.name), slotPath),
    ];
  });

// A tab's slots, as the editor lists them: the hull's of its categories, and
// those inside a fitted module, under the module slot's path.
const tabSlots = (
  slots: LoadoutSlot[],
  categories: HardpointCategoryEnum[],
  parentPath?: string,
): ComponentRow[] =>
  slots.flatMap((slot) => {
    const slotPath = parentPath ? `${parentPath}/${slot.name}` : slot.name;
    if (slot.category === HardpointCategoryEnum.MODULE) {
      return tabSlots(slot.slots, categories, slotPath);
    }
    if (!slot.category || !categories.includes(slot.category)) return [];

    return swappedIn([slot], undefined, parentPath);
  });

const componentSections = computed(() =>
  COMPONENT_TABS.map((tab) => ({
    key: tab.id,
    label: t(`labels.vehicleLoadout.tabs.${tab.id}`),
    rows: tabSlots(loadoutSlots.value ?? [], tab.categories),
  })),
);

// What the loadout fits, category by category, as badges: the module or part
// by name, the slot it sits in on hover, refused ones in red. The loadout's
// page carries the full hardpoint list.
type SummaryItem = {
  key: string;
  label: string;
  slot: string;
  refused?: string;
  // Not what the ship comes with.
  changed: boolean;
  testId: string;
  count: number;
};

// The same part in several slots, as one badge with a count; the slots are
// listed on hover.
const grouped = (items: Omit<SummaryItem, "count">[]) =>
  items.reduce<SummaryItem[]>((groups, item) => {
    const group = groups.find(
      (other) =>
        other.label === item.label &&
        other.refused === item.refused &&
        other.changed === item.changed,
    );
    if (group) {
      group.count += 1;
      group.slot = `${group.slot}, ${item.slot}`;
    } else {
      groups.push({ ...item, count: 1 });
    }

    return groups;
  }, []);

const summarySections = computed(() =>
  [
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      items: grouped(
        moduleRows.value.map((row) => ({
          key: row.slotPath,
          label: row.module.name,
          slot: slotLabel(row.slotPath),
          refused: refusedReason(row.slotPath),
          changed: !row.module.stock,
          testId: "vehicle-loadout-view-item",
        })),
      ),
    },
    ...componentSections.value.map((section) => ({
      key: section.key,
      label: section.label,
      items: grouped(
        section.rows.map((row) => ({
          key: row.slotPath,
          label: row.slot.fitted?.name || t("labels.loadoutPicker.emptySocket"),
          slot: row.label,
          refused: refusedReason(row.slotPath),
          changed: true,
          testId: "vehicle-loadout-view-component",
        })),
      ),
    })),
  ]
    .filter((section) => section.items.length)
    .map((section) => ({
      ...section,
      refused: section.items.some((item) => item.refused),
    })),
);

const pillVariant = (item: SummaryItem) => {
  if (item.refused) return PillVariantsEnum.DANGER;

  return item.changed ? PillVariantsEnum.WARNING : PillVariantsEnum.NEUTRAL;
};

// The band over the picture names the loadout, and the dialog by it.
const title = computed(
  () =>
    props.loadout?.name ||
    t("headlines.vehicleLoadout", {
      vehicle: props.vehicle.name || props.vehicle.model?.name,
    }),
);

const previewImage = computed(
  () =>
    props.vehicle.image?.mediumUrl ||
    props.vehicle.image?.url ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

const imageLoaded = ref(false);

watch(previewImage, () => {
  imageLoaded.value = false;
});

const { loadoutEditorAvailable } = useLoadoutEditor();

// The owner's way into the editor, where the editor is available.
const editVisible = computed(
  () => props.editable && loadoutEditorAvailable(props.vehicle),
);

const comlink = useComlink();

const { openLoadoutModal } = useVehicleModals();

const vehicleRoute = useVehicleRoute();

// The loadout's own page, with the ship page's hardpoints and figures.
const loadoutPage = computed(() =>
  props.loadout?.id
    ? vehicleRoute("hangar-vehicle-loadout", props.vehicle as Vehicle, {
        loadout: props.loadout.id,
      })
    : undefined,
);

const edit = () => {
  comlink.emit("close-modal");
  openLoadoutModal(props.vehicle, {
    editable: true,
    loadoutId: props.loadout?.id,
    tab: VehicleLoadoutTabsEnum.MODULES,
  });
};
</script>

<template>
  <Modal :title="title" :loading="loading" flush>
    <template #hero>
      <header
        class="loadout-view__hero"
        :class="{ 'skeleton-well': previewImage && !imageLoaded }"
      >
        <img
          v-if="previewImage"
          :src="previewImage"
          :alt="vehicle.model.name"
          class="loadout-view__image"
          :class="{ 'loadout-view__image--loaded': imageLoaded }"
          @load="imageLoaded = true"
        />
        <div class="loadout-view__band">
          <div class="loadout-view__ship">
            <span class="loadout-view__manufacturer">
              <!-- eslint-disable-next-line vue/no-v-html -->
              <span v-html="vehicle.model.manufacturer?.name" />
              · {{ vehicle.model.name }}
              <template v-if="vehicle.name"> · {{ vehicle.name }}</template>
            </span>
            <h2
              class="loadout-view__name"
              data-test="vehicle-loadout-view-name"
            >
              {{ title }}
            </h2>
          </div>
          <div class="loadout-view__pills">
            <Pill
              v-if="loadout?.active"
              :variant="PillVariantsEnum.SUCCESS"
              data-test="vehicle-loadout-view-active"
            >
              {{ t("labels.loadout.active") }}
            </Pill>
          </div>
        </div>
      </header>
    </template>

    <div
      class="loadout-view"
      data-test="vehicle-loadout-view"
      :aria-busy="loading || undefined"
    >
      <div class="loadout-view__body">
        <section
          v-if="changesLoading && editable && flightReady"
          class="loadout-view__changes"
          aria-hidden="true"
          data-test="vehicle-loadout-view-changes-skeleton"
        >
          <h3 class="loadout-view__title">
            {{ t("labels.vehicleLoadout.againstStock") }}
          </h3>
          <div class="loadout-view__tiles">
            <div
              v-for="tile in MAX_TILES"
              :key="tile"
              class="loadout-view__tile"
            >
              <span class="skeleton-bar loadout-view__skeleton-label" />
              <span class="skeleton-bar loadout-view__skeleton-value" />
              <span class="skeleton-bar loadout-view__skeleton-delta" />
            </div>
          </div>
        </section>

        <section
          v-else-if="keyChanges.length"
          class="loadout-view__changes"
          data-test="vehicle-loadout-view-changes"
        >
          <h3 class="loadout-view__title">
            {{ t("labels.vehicleLoadout.againstStock") }}
          </h3>
          <dl class="loadout-view__tiles">
            <div
              v-for="figure in keyChanges"
              :key="figure.key"
              class="loadout-view__tile"
              :data-test="`vehicle-loadout-view-changes-${figure.key}`"
            >
              <dt>{{ figure.label }}</dt>
              <dd class="loadout-view__tile-value">
                {{
                  figure.unit ? `${figure.value} ${figure.unit}` : figure.value
                }}
              </dd>
              <dd
                class="loadout-view__tile-delta"
                :class="`loadout-view__tile-delta--${figure.tone}`"
              >
                {{ figure.deltaLabel }}
              </dd>
            </div>
          </dl>
          <LoadoutChanges
            v-if="otherChanges.length"
            :figures="otherChanges"
            test-id="vehicle-loadout-view-changes"
          />
        </section>

        <Alert
          v-if="problems.length"
          :variant="AlertVariantsEnum.WARNING"
          :size="AlertSizesEnum.COMPACT"
          :title="t('labels.vehicleLoadout.refused.title')"
          data-test="vehicle-loadout-view-refused"
        >
          <p v-if="editVisible">
            {{ t("labels.vehicleLoadout.refused.editToReplace") }}
          </p>
          <ul class="loadout-view__refused">
            <li v-for="problem in problems" :key="problem.slotPath">
              {{ describe(problem) }}
            </li>
          </ul>
        </Alert>

        <section
          v-if="fittedLoading"
          class="loadout-view__fitted"
          aria-hidden="true"
          data-test="vehicle-loadout-view-fitted-skeleton"
        >
          <h3 class="loadout-view__title">
            {{ t("labels.vehicleLoadout.fitted") }}
          </h3>
          <div class="loadout-view__cards">
            <div v-for="card in 2" :key="card" class="loadout-view__card">
              <span class="skeleton-bar loadout-view__skeleton-label" />
              <div class="loadout-view__badges">
                <span class="skeleton-bar loadout-view__skeleton-pill" />
                <span class="skeleton-bar loadout-view__skeleton-pill" />
              </div>
            </div>
          </div>
        </section>

        <section
          v-else-if="summarySections.length"
          class="loadout-view__fitted"
        >
          <h3 class="loadout-view__title">
            {{ t("labels.vehicleLoadout.fitted") }}
          </h3>
          <div class="loadout-view__cards">
            <section
              v-for="section in summarySections"
              :key="section.key"
              class="loadout-view__card"
              :class="{ 'loadout-view__card--refused': section.refused }"
              :data-test="`vehicle-loadout-view-${section.key}`"
            >
              <h4 class="loadout-view__card-title">{{ section.label }}</h4>
              <ul class="loadout-view__badges">
                <li v-for="item in section.items" :key="item.key">
                  <Pill
                    v-tooltip="
                      item.refused
                        ? `${item.slot} · ${item.refused}`
                        : item.slot
                    "
                    :variant="pillVariant(item)"
                    :data-test="item.testId"
                    :data-refused="item.refused ? true : undefined"
                    :data-changed="item.changed ? true : undefined"
                  >
                    {{ item.label }}
                    <span v-if="item.count > 1" class="loadout-view__count">
                      ×{{ item.count }}
                    </span>
                  </Pill>
                </li>
              </ul>
            </section>
          </div>
        </section>

        <p
          v-else
          class="loadout-view__empty"
          data-test="vehicle-loadout-view-empty"
        >
          {{ t("labels.vehicleLoadout.nothingFitted") }}
        </p>
      </div>
    </div>

    <template v-if="editVisible || (editable && loadoutPage)" #footer>
      <Btn
        v-if="editVisible"
        :variant="BtnVariantsEnum.GHOST"
        data-test="vehicle-loadout-view-edit"
        @click="edit"
      >
        <i class="fa-duotone fa-screwdriver-wrench" />
        {{ t("actions.vehicleLoadout.editLoadout") }}
      </Btn>
      <Btn
        v-if="editable && loadoutPage"
        :to="loadoutPage"
        data-test="vehicle-loadout-view-page"
        @click="comlink.emit('close-modal')"
      >
        <i class="fa-duotone fa-file-lines" />
        {{ t("actions.vehicleLoadout.openLoadoutPage") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
