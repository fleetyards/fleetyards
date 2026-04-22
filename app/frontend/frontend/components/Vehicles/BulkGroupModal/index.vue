<script lang="ts">
export default {
  name: "VehiclesBulkGroupModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import {
  type HangarGroup,
  useHangarGroups as useHangarGroupsQuery,
} from "@/services/fyApi";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  vehicleIds: string[];
};

const props = defineProps<Props>();

const { t } = useI18n();

const comlink = useComlink();

const submitting = ref(false);

const hangarGroupIds = ref<string[]>([]);

const { data: hangarGroupsData } = useHangarGroupsQuery();

const hangarGroups = computed<HangarGroup[]>(() => {
  return hangarGroupsData.value || [];
});

const selected = (groupId: string) => {
  return hangarGroupIds.value.includes(groupId);
};

const changeGroup = (group: HangarGroup) => {
  if (hangarGroupIds.value.includes(group.id)) {
    const index = hangarGroupIds.value.findIndex(
      (groupId) => groupId === group.id,
    );
    if (index > -1) {
      hangarGroupIds.value.splice(index, 1);
    }
  } else {
    hangarGroupIds.value.push(group.id);
  }
};

const { useUpdateBulkMutation } = useVehicleMutations();
const { mutateAsync: bulkUpdateMutateAsync } = useUpdateBulkMutation();

const save = async () => {
  submitting.value = true;

  await bulkUpdateMutateAsync({
    data: {
      ids: props.vehicleIds,
      hangarGroupIds: hangarGroupIds.value,
    },
  })
    .then(() => {
      comlink.emit("close-modal");
    })
    .finally(() => {
      submitting.value = false;
    });
};
</script>

<template>
  <Modal :title="t('headlines.vehicle.bulkGroupEdit')">
    <p class="hint">
      <i class="fa-light fa-info-circle" />
      {{ t("labels.vehicle.bulkGroupEdit.hint") }}
    </p>

    <form id="vehicle-bulk" @submit.prevent="save">
      <div class="row">
        <div v-if="hangarGroups.length" class="col-12">
          <h3>Groups:</h3>
          <div class="row">
            <div
              v-for="group in hangarGroups"
              :key="group.id"
              class="col-12 col-md-6"
            >
              <FormToggle
                :name="group.name"
                :label="group.name"
                :value="selected(group.id)"
                @input="changeGroup(group)"
              />
            </div>
          </div>
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          :size="BtnSizesEnum.LARGE"
          data-test="vehicle-save"
          :inline="true"
          @click="save"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "./index.scss";
</style>
