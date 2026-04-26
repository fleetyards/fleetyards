<script lang="ts">
export default {
  name: "HangarVehicleLoadoutsPage",
};
</script>

<script lang="ts" setup>
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Pill from "@/shared/components/base/Pill/index.vue";
import InlineEditableList from "@/shared/components/InlineEditableList/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import { useI18n } from "@/shared/composables/useI18n";
import { useMobile } from "@/shared/composables/useMobile";
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
} from "@/services/fyApi";
import { useQueryClient } from "@tanstack/vue-query";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();
const queryClient = useQueryClient();

const mobile = useMobile();

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

const onStartEdit = (record: VehicleLoadout) => {
  editForm.value = {
    name: record.name,
    url: record.url || "",
  };
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
  <div>
    <div
      v-if="erkulShipUrl || spviewerShipUrl"
      class="loadouts-page__ship-links"
    >
      <span v-if="!mobile">{{ t("labels.loadout.planOn") }}</span>
      <BtnGroup inline>
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
      </BtnGroup>
    </div>

    <div class="flex items-center justify-between loadouts-page__toolbar">
      <Btn
        :size="BtnSizesEnum.SMALL"
        :disabled="editableList?.creating"
        @click="editableList?.startCreate()"
      >
        <i class="fa-duotone fa-plus" />
        {{ t("actions.add") }}
      </Btn>
    </div>

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
          <Pill v-if="item.active" variant="success" uppercase>
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
          </div>
        </div>
      </template>

      <template #actions="{ item }">
        <Btn
          v-if="!item.active"
          v-tooltip="t('labels.loadout.activate')"
          :size="BtnSizesEnum.SMALL"
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
          v-model="editForm.url"
          name="edit-loadout-url"
          :placeholder="t('labels.loadout.urlPlaceholder')"
          :no-label="true"
          class="loadouts-page__edit-url"
        />
      </template>
    </InlineEditableList>
  </div>
</template>

<style lang="scss" scoped>
@import "loadouts";
</style>
