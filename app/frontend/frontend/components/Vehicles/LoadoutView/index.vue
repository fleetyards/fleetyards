<script lang="ts">
export default {
  name: "VehicleLoadoutView",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import AddonOption from "@/frontend/components/Models/AddonOption/index.vue";
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
import { useModuleContents } from "@/frontend/composables/useModuleContents";
import { useLoadoutSlotLabel } from "@/frontend/composables/useLoadoutSlotLabel";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";
import { useLoadoutModules } from "@/frontend/composables/useLoadoutModules";
import {
  COMPONENT_TABS,
  loadoutValues,
  slotName,
} from "@/frontend/composables/useComponentFitting";
import { useLoadoutDiff } from "@/frontend/composables/useLoadoutDiff";
import { useLoadoutFitting } from "@/frontend/composables/useLoadoutFitting";
import {
  HardpointCategoryEnum,
  type LoadoutSlot,
  type ModelModule,
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

const { contents } = useModuleContents();

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

const refusedBadges = (slotPath: string) => {
  const problem = refusedAt.value.get(slotPath);

  return problem
    ? [
        {
          key: "refused",
          label: `${t("labels.vehicleLoadout.refused.badge")}: ${reason(problem)}`,
          variant: PillVariantsEnum.DANGER,
        },
      ]
    : [];
};

// What the loadout changes on the ship as the game files deliver it, worked out
// by the editor's own diff. The parts in it are known only from the owner's
// slot tree, so a visitor sees what the modules change.
const flightReady = computed(
  () =>
    model.value?.productionStatus === ModelProductionStatusEnum.FLIGHT_READY,
);

const { fitting, hullSlots, modelHardpoints, modelModules } = useLoadoutFitting(
  {
    modelSlug: () => model.value?.slug,
    loadoutSlots,
    items: () => props.loadout?.items,
    enabled: () => props.editable && flightReady.value,
  },
);

const { componentFigure } = fitting;

const loadoutDiff = useLoadoutDiff(fitting);

const changesFromStock = computed(() => {
  const measure = (modules: ModelModule[], values: Record<string, string>) =>
    loadoutDiff.measure({
      hullCargo: model.value?.metrics.cargo || 0,
      modules,
      hardpoints: modelHardpoints.value ?? [],
      tree: fitting.resolve(hullSlots.value ?? [], values),
      weaponPoolSize: model.value?.metrics.weaponPoolSize,
    });

  const stockModules = modelModules.value.filter((mod) => mod.stock);
  const { modules, components } = loadoutValues(props.loadout?.items);

  return loadoutDiff.diff(
    measure(
      stockModules,
      Object.fromEntries(
        stockModules.flatMap((mod) => (mod.slot ? [[mod.slot, mod.id]] : [])),
      ),
    ),
    measure(
      moduleRows.value.map((row) => row.module),
      { ...modules, ...components },
    ),
    COMPONENT_TABS,
  ).changed;
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

// One section per category with something fitted, so the view grows with
// the categories rather than listing the ones still to come.
const sections = computed(() =>
  [
    {
      key: "modules",
      label: t("labels.vehicleLoadout.tabs.modules"),
      category: HardpointCategoryEnum.MODULE,
      rows: moduleRows.value,
    },
  ].filter((section) => section.rows.length),
);

const fittedComponentSections = computed(() =>
  componentSections.value.filter((section) => section.rows.length),
);

const badges = (mod: ModelModule, slotPath: string) => [
  ...(mod.stock
    ? [
        {
          key: "stock",
          label: t("labels.vehicleLoadout.stock"),
          variant: PillVariantsEnum.NEUTRAL,
        },
      ]
    : []),
  ...refusedBadges(slotPath),
];

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
        v-for="section in sections"
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
        <dl class="loadout-view__slots">
          <div
            v-for="row in section.rows"
            :key="row.slotPath"
            class="loadout-view__slot"
          >
            <dt>{{ slotLabel(row.slotPath) }}</dt>
            <dd>
              <AddonOption
                :name="row.module.name"
                :image="row.module.media?.storeImage?.smallUrl"
                :contents="row.module.description || contents(row.module)"
                :badges="badges(row.module, row.slotPath)"
                :editable="false"
                test-id="vehicle-loadout-view-item"
              />
            </dd>
          </div>
        </dl>
      </section>

      <section
        v-for="section in fittedComponentSections"
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
        <dl class="loadout-view__slots">
          <div
            v-for="row in section.rows"
            :key="row.slotPath"
            class="loadout-view__slot"
          >
            <dt>{{ row.label }}</dt>
            <dd>
              <AddonOption
                :name="
                  row.slot.fitted?.name || t('labels.loadoutPicker.emptySocket')
                "
                :contents="componentFigure(row.slot.fitted)"
                :badges="refusedBadges(row.slotPath)"
                :editable="false"
                test-id="vehicle-loadout-view-component"
              />
            </dd>
          </div>
        </dl>
      </section>

      <p
        v-if="!sections.length && !fittedComponentSections.length"
        class="loadout-view__empty"
        data-test="vehicle-loadout-view-empty"
      >
        {{ t("labels.vehicleLoadout.nothingFitted") }}
      </p>
    </div>

    <template v-if="editVisible" #footer>
      <Btn data-test="vehicle-loadout-view-edit" @click="edit">
        <i class="fa-duotone fa-screwdriver-wrench" />
        {{ t("actions.vehicleLoadout.editLoadout") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
