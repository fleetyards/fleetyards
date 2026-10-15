<script lang="ts">
export default {
  name: "HangarVehicleLoadoutsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import VehicleTabLayout from "@/frontend/components/Vehicles/TabLayout/index.vue";

import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleModals } from "@/frontend/composables/useVehicleModals";
import { useFeatures } from "@/frontend/composables/useFeatures";
import { useLoadoutEditor } from "@/frontend/composables/useLoadoutEditor";
import { VehicleLoadoutTabsEnum } from "@/frontend/components/Vehicles/LoadoutModal/types";
import {
  type Vehicle,
  type VehicleLoadout,
  type VehicleLoadoutInput,
  useVehicleLoadouts,
  useCreateVehicleLoadout,
  useUpdateVehicleLoadout,
  useDestroyVehicleLoadout,
  useActivateVehicleLoadout,
  getVehicleLoadoutsQueryKey,
  VehicleLoadoutKindEnum,
  ModelProductionStatusEnum,
  FeatureFlagName,
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const erkulShipUrl = computed(() => {
  const identifier =
    props.vehicle.model?.erkulIdentifier || props.vehicle.model?.scIdentifier;
  if (!identifier) return undefined;
  return `https://www.erkul.games/ship/${identifier}`;
});

const spviewerShipUrl = computed(() => {
  const identifier = props.vehicle.model?.scIdentifier;
  if (!identifier) return undefined;
  return `https://www.spviewer.eu/performance?ship=${identifier}`;
});

const { data: loadouts, isLoading } = useVehicleLoadouts(props.vehicle.id);

// The API refuses a loadout of either kind for a ship still in concept or
// production, so the page does not offer one.
const flightReady = computed(
  () =>
    props.vehicle.model?.productionStatus ===
    ModelProductionStatusEnum.FLIGHT_READY,
);

const loadoutItems = computed(() => (loadouts.value as VehicleLoadout[]) || []);

const editableList = ref<{
  editingId: string | null;
  creating: boolean;
  startCreate: () => void;
  finishEdit: () => void;
  finishCreate: () => void;
} | null>(null);

const invalidateLoadouts = () => {
  void queryClient.invalidateQueries({
    queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
  });
};

// Create
const createForm = ref<VehicleLoadoutInput>({});

const onStartCreate = () => {
  createForm.value = {};
};

const createMutation = useCreateVehicleLoadout({
  mutation: { onSettled: invalidateLoadouts },
});

const onSaveCreate = async () => {
  await createMutation.mutateAsync({
    vehicleId: props.vehicle.id,
    data: createForm.value,
  });

  editableList.value?.finishCreate();
};

// Edit
const editForm = ref<VehicleLoadoutInput>({});

// A fleetyards loadout has no url to edit; its fitting is changed in the
// loadout editor.
const editingLink = ref(true);

const onStartEdit = (record: VehicleLoadout) => {
  editingLink.value = record.kind === VehicleLoadoutKindEnum.LINK;
  editForm.value = editingLink.value
    ? { name: record.name, url: record.url || "" }
    : { name: record.name };
};

const updateMutation = useUpdateVehicleLoadout({
  mutation: { onSettled: invalidateLoadouts },
});

const onSaveEdit = async () => {
  const id = editableList.value?.editingId;
  if (!id) return;

  await updateMutation.mutateAsync({
    vehicleId: props.vehicle.id,
    id,
    data: editForm.value,
  });

  editableList.value?.finishEdit();
};

// Delete
const destroyMutation = useDestroyVehicleLoadout({
  mutation: { onSettled: invalidateLoadouts },
});

const onDestroy = async (record: VehicleLoadout) => {
  await destroyMutation.mutateAsync({
    vehicleId: props.vehicle.id,
    id: record.id,
  });
};

// A fleetyards loadout is fitted in the loadout editor, not inline; until the
// editor is switched on the page keeps to linked builds.
const { openLoadoutModal } = useVehicleModals();

const { isFeatureEnabled } = useFeatures();

const editorEnabled = computed(() =>
  isFeatureEnabled(FeatureFlagName.LOADOUT_EDITOR),
);

// The new-loadout button stays, disabled with its reason, on a ship that is not
// flight ready; an existing loadout on one has no fitting to open.
const { loadoutEditorAvailable } = useLoadoutEditor();

const fittingEditable = computed(() => loadoutEditorAvailable(props.vehicle));

const editFitting = (record: VehicleLoadout) => {
  openLoadoutModal(props.vehicle, {
    editable: true,
    loadoutId: record.id,
    tab: VehicleLoadoutTabsEnum.MODULES,
  });
};

const newFleetyardsLoadout = () => {
  openLoadoutModal(props.vehicle, {
    editable: true,
    newLoadout: true,
    tab: VehicleLoadoutTabsEnum.MODULES,
  });
};

// Activate
const activateMutation = useActivateVehicleLoadout({
  mutation: { onSettled: invalidateLoadouts },
});

const onActivate = async (record: VehicleLoadout) => {
  await activateMutation.mutateAsync({
    vehicleId: props.vehicle.id,
    id: record.id,
  });
};
</script>

<template>
  <VehicleTabLayout class="loadouts-page">
    <InlineEditableList
      ref="editableList"
      empty-name="loadouts"
      :items="loadoutItems"
      :loading="isLoading"
      confirm-destroy-text="Are you sure you want to delete this loadout?"
      @start-edit="onStartEdit"
      @save-edit="onSaveEdit"
      @start-create="onStartCreate"
      @save-create="onSaveCreate"
      @destroy="onDestroy"
    >
      <template #display="{ item }">
        <div class="loadouts-page__item-display">
          <Pill
            v-if="item.active"
            :variant="PillVariantsEnum.SUCCESS"
            uppercase
          >
            {{ t("labels.loadout.active") }}
          </Pill>
          <div class="loadouts-page__item-info">
            <span class="loadouts-page__item-name">
              {{ item.name }}
            </span>
            <div v-if="item.url" class="loadouts-page__item-links">
              <a :href="item.url" target="_blank" rel="noopener">
                {{ item.urlSource || item.url }}
              </a>
            </div>
            <div v-else class="loadouts-page__item-links">
              {{ t("labels.loadout.fleetyards") }}
            </div>
          </div>
        </div>
      </template>

      <template #actions="{ item }">
        <Btn
          v-if="
            fittingEditable && item.kind === VehicleLoadoutKindEnum.FLEETYARDS
          "
          v-tooltip="t('actions.vehicleLoadout.editLoadout')"
          :data-test="`loadout-edit-fitting-${item.id}`"
          @click="editFitting(item)"
        >
          <i class="fa-duotone fa-screwdriver-wrench" />
        </Btn>
        <Btn
          v-if="!item.active"
          v-tooltip="t('labels.loadout.activate')"
          @click="onActivate(item)"
        >
          <i class="fa-duotone fa-circle-check" />
        </Btn>
      </template>

      <template #create>
        <FormInput
          v-model="createForm.url"
          name="create-loadout-url"
          :placeholder="t('labels.loadout.urlPlaceholder')"
          :no-label="true"
          inline
        />
      </template>

      <template #edit>
        <FormInput
          v-model="editForm.name"
          name="edit-loadout-name"
          :placeholder="t('labels.loadout.namePlaceholder')"
          :no-label="true"
          class="loadouts-page__edit-name"
        />
        <FormInput
          v-if="editingLink"
          v-model="editForm.url"
          name="edit-loadout-url"
          :placeholder="t('labels.loadout.urlPlaceholder')"
          :no-label="true"
          class="loadouts-page__edit-url"
        />
      </template>
    </InlineEditableList>

    <template #side>
      <span
        v-tooltip="
          flightReady ? undefined : t('labels.vehicleLoadout.notFlightReady')
        "
        class="loadouts-page__add-wrapper"
      >
        <Btn
          class="loadouts-page__add"
          :disabled="editableList?.creating || !flightReady"
          data-test="loadouts-add"
          @click="editableList?.startCreate()"
        >
          <i class="fa-duotone fa-plus" />
          {{ t("actions.add") }}
        </Btn>
        <Btn
          v-if="editorEnabled"
          class="loadouts-page__add"
          :disabled="!flightReady || !vehicle.model?.hasModules"
          data-test="loadouts-new-fleetyards"
          @click="newFleetyardsLoadout"
        >
          <i class="fa-duotone fa-screwdriver-wrench" />
          {{ t("actions.vehicleLoadout.newLoadout") }}
        </Btn>
      </span>

      <MetricsCard
        v-if="erkulShipUrl || spviewerShipUrl"
        :title="t('labels.vehicleOverview.planLoadout')"
        variant="slim"
      >
        <div class="loadouts-page__ship-links">
          <Btn v-if="erkulShipUrl" :href="erkulShipUrl" class="erkul-link">
            <i />
            {{ t("labels.hardpoints.erkul") }}
          </Btn>
          <Btn
            v-if="spviewerShipUrl"
            :href="spviewerShipUrl"
            class="spviewer-link"
          >
            <i />
            {{ t("labels.hardpoints.spviewer") }}
          </Btn>
        </div>
      </MetricsCard>
    </template>
  </VehicleTabLayout>
</template>

<style lang="scss" scoped>
.loadouts-page {
  &__add {
    width: 100%;

    & + & {
      margin-top: 8px;
    }
  }

  // Holds the tooltip a disabled button cannot, and the button's full width.
  &__add-wrapper {
    display: block;
  }

  &__ship-links {
    display: flex;
    flex-direction: column;
    gap: 8px;

    > * {
      width: 100%;
    }
  }

  &__item-display {
    display: flex;
    align-items: center;
    gap: 10px;
    flex: 1;
  }

  &__item-info {
    display: flex;
    flex-direction: column;
    gap: 2px;
  }

  &__item-name {
    font-weight: 600;
  }

  &__edit-name {
    flex: 1 !important;
  }

  &__edit-url {
    flex: 2 !important;
  }

  &__item-links {
    display: flex;
    gap: 10px;
    font-size: 0.85rem;
  }
}
</style>
