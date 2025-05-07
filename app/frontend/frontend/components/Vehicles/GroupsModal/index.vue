<script lang="ts">
export default {
  name: "VehicleGroupsModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import {
  useHangarGroups as useHangarGroupsQuery,
  useUpdateVehicle as useUpdateVehicleMutation,
  type Vehicle,
  type VehicleUpdateInput,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const submitting = ref(false);

const { data: hangarGroups } = useHangarGroupsQuery();

const initialValues = ref<VehicleUpdateInput>({
  hangarGroupIds: props.vehicle.hangarGroupIds,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [hangarGroupIds] = defineField("hangarGroupIds");

onMounted(() => {
  setupForm();
});

watch(
  () => props.vehicle,
  () => {
    setupForm();
  },
  { deep: true },
);

const setupForm = () => {
  initialValues.value = {
    hangarGroupIds: props.vehicle.hangarGroupIds,
  };
};

const comlink = useComlink();

const mutation = useUpdateVehicleMutation();

const onSubmit = handleSubmit(async (values) => {
  submitting.value = true;

  await mutation
    .mutateAsync({
      id: props.vehicle.id,
      data: values,
    })
    .then(() => {
      comlink.emit("close-modal");
    })
    .catch((error) => {
      console.error(error);
    })
    .finally(() => {
      submitting.value = false;
    });
});
</script>

<template>
  <Modal :title="t('headlines.editGroups', { vehicle: vehicle.model.name })">
    <form :id="`vehicle-${vehicle.id}`" @submit.prevent="onSubmit">
      <div v-if="hangarGroups && hangarGroups.length" class="row">
        <div
          v-for="group in hangarGroups"
          :key="group.id"
          class="col-12 col-md-6"
        >
          <FormCheckbox
            v-model="hangarGroupIds"
            :checkbox-value="group.id"
            :name="group.name"
            :label="group.name"
          />
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-${vehicle.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          data-test="vehicle-save"
          :inline="true"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>
