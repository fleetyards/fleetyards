<script lang="ts">
export default {
  name: "VehicleLoadoutView",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import Specs from "@/frontend/components/Vehicles/Overview/Specs/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import {
  AlertSizesEnum,
  AlertVariantsEnum,
} from "@/shared/components/base/Alert/types";
import { useLoadoutProblems } from "@/frontend/composables/useLoadoutProblems";
import HardpointCategoryIcon from "@/frontend/components/Models/Hardpoints/CategoryIcon/index.vue";
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

const { moduleRows, moduleCargo } = useLoadoutModules(
  () => model.value?.slug,
  () => props.loadout,
);

// The parts swapped in or taken out, read off the loadout's slot tree. Only the owner can
// read that tree, so only the owner sees them.
const { data: loadoutSlots } = useVehicleLoadoutSlots(
  () => props.vehicle.id,
  () => props.loadout?.id ?? "",
  { query: { enabled: () => props.editable && !!props.loadout?.id } },
);

// Only the owner can read what the build refuses, as with the slot tree.
const { problems, reason, describe } = useLoadoutProblems(
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

const { changesFromStock } = useLoadoutFitting({
  model,
  loadoutSlots,
  items: () => props.loadout?.items,
  enabled: () => props.editable && flightReady.value,
});

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
    category: tab.categories[0],
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
  testId: string;
};

const summarySections = computed(() =>
  [
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      category: HardpointCategoryEnum.MODULE,
      items: moduleRows.value.map<SummaryItem>((row) => ({
        key: row.slotPath,
        label: row.module.name,
        slot: slotLabel(row.slotPath),
        refused: refusedReason(row.slotPath),
        testId: "vehicle-loadout-view-item",
      })),
    },
    ...componentSections.value.map((section) => ({
      key: section.key,
      label: section.label,
      category: section.category,
      items: section.rows.map<SummaryItem>((row) => ({
        key: row.slotPath,
        label: row.slot.fitted?.name || t("labels.loadoutPicker.emptySocket"),
        slot: row.label,
        refused: refusedReason(row.slotPath),
        testId: "vehicle-loadout-view-component",
      })),
    })),
  ].filter((section) => section.items.length),
);

const previewImage = computed(
  () =>
    props.vehicle.image?.mediumUrl ||
    props.vehicle.image?.url ||
    model.value?.media.storeImage?.mediumUrl ||
    model.value?.media.storeImage?.url,
);

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
  <Modal
    :title="
      loadout?.name ||
      t('headlines.vehicleLoadout', {
        vehicle: vehicle.name || vehicle.model?.name,
      })
    "
  >
    <div class="loadout-view" data-test="vehicle-loadout-view">
      <div class="loadout-view__ship">
        <img
          v-if="previewImage"
          :src="previewImage"
          :alt="vehicle.model.name"
          class="loadout-view__image"
        />
        <div class="loadout-view__ship-info">
          <p class="loadout-view__model">
            <!-- eslint-disable-next-line vue/no-v-html -->
            <span v-html="vehicle.model.manufacturer?.name" />
            <strong>{{ vehicle.name || vehicle.model.name }}</strong>
          </p>
          <Specs :model="vehicle.model" :module-cargo="moduleCargo" />
        </div>
      </div>

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

      <LoadoutChanges
        v-if="changesFromStock.length"
        :title="t('labels.vehicleLoadout.againstStock')"
        :figures="changesFromStock"
        test-id="vehicle-loadout-view-changes"
      />

      <section
        v-for="section in summarySections"
        :key="section.key"
        class="loadout-view__section"
        :data-test="`vehicle-loadout-view-${section.key}`"
      >
        <h3>
          <HardpointCategoryIcon
            :category="section.category"
            class="loadout-view__icon"
          />
          {{ section.label }}
        </h3>
        <ul class="loadout-view__badges">
          <li v-for="item in section.items" :key="item.key">
            <Pill
              v-tooltip="
                item.refused ? `${item.slot} · ${item.refused}` : item.slot
              "
              :variant="
                item.refused
                  ? PillVariantsEnum.DANGER
                  : PillVariantsEnum.NEUTRAL
              "
              :data-test="item.testId"
              :data-refused="item.refused ? true : undefined"
            >
              {{ item.label }}
            </Pill>
          </li>
        </ul>
      </section>

      <p
        v-if="!summarySections.length"
        class="loadout-view__empty"
        data-test="vehicle-loadout-view-empty"
      >
        {{ t("labels.vehicleLoadout.nothingFitted") }}
      </p>
    </div>

    <template v-if="editVisible || (editable && loadoutPage)" #footer>
      <Btn
        v-if="editable && loadoutPage"
        :to="loadoutPage"
        data-test="vehicle-loadout-view-page"
        @click="comlink.emit('close-modal')"
      >
        <i class="fa-duotone fa-file-lines" />
        {{ t("actions.vehicleLoadout.openLoadoutPage") }}
      </Btn>
      <Btn
        v-if="editVisible"
        data-test="vehicle-loadout-view-edit"
        @click="edit"
      >
        <i class="fa-duotone fa-screwdriver-wrench" />
        {{ t("actions.vehicleLoadout.editLoadout") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
