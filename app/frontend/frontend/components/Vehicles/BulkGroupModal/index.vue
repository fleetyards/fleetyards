<script lang="ts">
export default {
  name: "VehiclesBulkGroupModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";
// import vehiclesCollection from "@/frontend/api/collections/Vehicles";
// import hangarGroupsCollection from "@/frontend/api/collections/HangarGroups";
import type { HangarGroup } from "@/services/fyApi";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";

type Props = {
  vehicleIds: string[];
};

defineProps<Props>();

const { t } = useI18n();

const submitting = ref(false);

const hangarGroupIds = ref<string[]>([]);

const hangarGroups = computed(() => {
  return hangarGroupsCollection.records;
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

const comlink = useComlink();

const save = async () => {
  submitting.value = true;

  if (
    await vehiclesCollection.updateHangarGroupsBulk(
      this.vehicleIds,
      this.hangarGroupIds,
    )
  ) {
    comlink.emit("close-modal");
  }

  submitting.value = false;
};
</script>

<template>
  <Modal :title="t('headlines.vehicle.bulkGroupEdit')">
    <p class="hint">
      <i class="fal fa-info-circle" />
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
              <FormCheckbox
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
          form="vehicle-bulk"
          :loading="submitting"
          :type="BtnTypesEnum.SUBMIT"
          :size="BtnSizesEnum.LARGE"
          data-test="vehicle-save"
          :inline="true"
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
