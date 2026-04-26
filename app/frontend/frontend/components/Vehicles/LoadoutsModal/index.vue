<script lang="ts">
export default {
  name: "VehicleLoadoutsModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import {
  type Vehicle,
  type VehicleLoadout,
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
const comlink = useComlink();
const queryClient = useQueryClient();
const { displayConfirm, displayAlert } = useAppNotifications();

const { data: loadouts, isLoading } = useVehicleLoadouts(props.vehicle.id);

const createMutation = useCreateVehicleLoadout();
const updateMutation = useUpdateVehicleLoadout();
const destroyMutation = useDestroyVehicleLoadout();
const activateMutation = useActivateVehicleLoadout();

const newLoadoutName = ref("");
const editingLoadout = ref<VehicleLoadout | null>(null);
const editName = ref("");
const editErkulUrl = ref("");
const editSpviewerUrl = ref("");
const submitting = ref(false);

const invalidateLoadouts = () => {
  void queryClient.invalidateQueries({
    queryKey: getVehicleLoadoutsQueryKey(props.vehicle.id),
  });
};

const createLoadout = async () => {
  if (!newLoadoutName.value.trim()) return;

  submitting.value = true;

  await createMutation
    .mutateAsync({
      vehicleId: props.vehicle.id,
      data: {
        name: newLoadoutName.value.trim(),
        fromDefaults: true,
      },
    })
    .then(() => {
      newLoadoutName.value = "";
      invalidateLoadouts();
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message || "Error" });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const startEdit = (loadout: VehicleLoadout) => {
  editingLoadout.value = loadout;
  editName.value = loadout.name;
  editErkulUrl.value = loadout.erkulUrl || "";
  editSpviewerUrl.value = loadout.spviewerUrl || "";
};

const cancelEdit = () => {
  editingLoadout.value = null;
};

const saveEdit = async () => {
  if (!editingLoadout.value || !editName.value.trim()) return;

  submitting.value = true;

  await updateMutation
    .mutateAsync({
      vehicleId: props.vehicle.id,
      id: editingLoadout.value.id,
      data: {
        name: editName.value.trim(),
        erkulUrl: editErkulUrl.value || null,
        spviewerUrl: editSpviewerUrl.value || null,
      },
    })
    .then(() => {
      editingLoadout.value = null;
      invalidateLoadouts();
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message || "Error" });
    })
    .finally(() => {
      submitting.value = false;
    });
};

const activate = async (loadout: VehicleLoadout) => {
  await activateMutation
    .mutateAsync({
      vehicleId: props.vehicle.id,
      id: loadout.id,
    })
    .then(() => {
      invalidateLoadouts();
    })
    .catch((error) => {
      displayAlert({ text: error.response?.data?.message || "Error" });
    });
};

const remove = (loadout: VehicleLoadout) => {
  displayConfirm({
    text: t("messages.confirm.vehicle.destroy"),
    onConfirm: async () => {
      await destroyMutation
        .mutateAsync({
          vehicleId: props.vehicle.id,
          id: loadout.id,
        })
        .then(() => {
          invalidateLoadouts();
        })
        .catch((error) => {
          displayAlert({ text: error.response?.data?.message || "Error" });
        });
    },
  });
};
</script>

<template>
  <Modal
    :title="
      t('headlines.myVehicleLoadouts', {
        vehicle: vehicle.model?.name,
      })
    "
  >
    <div class="loadouts-modal">
      <div class="loadouts-modal__create">
        <form
          class="loadouts-modal__create-form"
          @submit.prevent="createLoadout"
        >
          <FormInput
            v-model="newLoadoutName"
            name="newLoadoutName"
            :placeholder="t('labels.loadout.namePlaceholder')"
            :no-label="true"
          />
          <Btn
            :loading="submitting"
            :disabled="!newLoadoutName.trim()"
            :inline="true"
            @click="createLoadout"
          >
            {{ t("actions.add") }}
          </Btn>
        </form>
      </div>

      <div v-if="isLoading" class="loadouts-modal__loading">
        <i class="fa fa-spinner fa-spin" />
      </div>

      <div v-else-if="!loadouts?.length" class="loadouts-modal__empty">
        {{ t("labels.loadout.empty") }}
      </div>

      <div v-else class="loadouts-modal__list">
        <div
          v-for="loadout in loadouts"
          :key="loadout.id"
          class="loadouts-modal__item"
          :class="{ 'loadouts-modal__item--active': loadout.active }"
        >
          <template v-if="editingLoadout?.id === loadout.id">
            <div class="loadouts-modal__item-edit">
              <FormInput v-model="editName" name="editName" :no-label="true" />
              <FormInput
                v-model="editErkulUrl"
                name="editErkulUrl"
                :placeholder="t('labels.loadout.erkulUrl')"
                :no-label="true"
              />
              <FormInput
                v-model="editSpviewerUrl"
                name="editSpviewerUrl"
                :placeholder="t('labels.loadout.spviewerUrl')"
                :no-label="true"
              />
              <div class="loadouts-modal__item-actions">
                <Btn :loading="submitting" :inline="true" @click="saveEdit">
                  {{ t("actions.save") }}
                </Btn>
                <Btn :inline="true" @click="cancelEdit">
                  {{ t("actions.cancel") }}
                </Btn>
              </div>
            </div>
          </template>
          <template v-else>
            <div class="loadouts-modal__item-info">
              <span class="loadouts-modal__item-name">
                {{ loadout.name }}
              </span>
              <span v-if="loadout.active" class="loadouts-modal__item-badge">
                {{ t("labels.loadout.active") }}
              </span>
              <div
                v-if="loadout.erkulUrl || loadout.spviewerUrl"
                class="loadouts-modal__item-links"
              >
                <a
                  v-if="loadout.erkulUrl"
                  :href="loadout.erkulUrl"
                  target="_blank"
                  rel="noopener"
                >
                  Erkul
                </a>
                <a
                  v-if="loadout.spviewerUrl"
                  :href="loadout.spviewerUrl"
                  target="_blank"
                  rel="noopener"
                >
                  SPViewer
                </a>
              </div>
            </div>
            <div class="loadouts-modal__item-actions">
              <Btn
                v-if="!loadout.active"
                :inline="true"
                size="small"
                @click="activate(loadout)"
              >
                {{ t("labels.loadout.activate") }}
              </Btn>
              <Btn :inline="true" size="small" @click="startEdit(loadout)">
                <i class="fa fa-pencil" />
              </Btn>
              <Btn :inline="true" size="small" @click="remove(loadout)">
                <i class="fa-light fa-trash" />
              </Btn>
            </div>
          </template>
        </div>
      </div>
    </div>

    <template #footer>
      <div class="float-sm-right">
        <Btn :inline="true" size="large" @click="comlink.emit('close-modal')">
          {{ t("actions.close") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
