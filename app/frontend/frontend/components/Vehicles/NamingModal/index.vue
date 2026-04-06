<script lang="ts">
export default {
  name: "VehicleNamingModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { transformErrors } from "@/frontend/utils/transformErrors";
import {
  type Vehicle,
  type VehicleUpdateInput,
  type ValidationError,
} from "@/services/fyApi";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { type ErrorType } from "@/services/axiosClient";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import AlternativeNamesInput from "./AlternativeNamesInput/index.vue";

type Props = {
  vehicle: Vehicle;
};

const props = defineProps<Props>();

const { t } = useI18n();

const initialValues = ref<VehicleUpdateInput>({
  name: props.vehicle.name,
  serial: props.vehicle.serial,
  nameVisible: props.vehicle.nameVisible,
  alternativeNames: props.vehicle.alternativeNames,
});

const { defineField, handleSubmit, setErrors } = useForm({
  initialValues: initialValues.value,
});

const [name] = defineField("name");
const [serial] = defineField("serial");
const [nameVisible] = defineField("nameVisible");
const [alternativeNames] = defineField("alternativeNames");

const submitting = ref(false);

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
    name: props.vehicle.name,
    serial: props.vehicle.serial,
    nameVisible: props.vehicle.nameVisible,
    alternativeNames: props.vehicle.alternativeNames,
  };
};

const vehicle = computed(() => props.vehicle);

const { useUpdateMutation } = useVehicleMutations();

const mutation = useUpdateMutation(vehicle);

const comlink = useComlink();

const { displayAlert } = useAppNotifications();

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
      const response = error as unknown as ErrorType<ValidationError>;

      if (response.response?.data?.errors) {
        setErrors(transformErrors(response.response.data.errors));

        displayAlert({
          text: response.response?.data?.message,
        });
      } else {
        displayAlert({
          text: response.response?.data?.message,
        });
      }
    })
    .finally(() => {
      submitting.value = false;
    });
});

const useName = (newName: string) => {
  name.value = newName;
};
</script>

<template>
  <Modal
    v-if="vehicle"
    :title="t('headlines.nameMyVehicle', { vehicle: vehicle?.model?.name })"
  >
    <form :id="`vehicle-${vehicle.id}`" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <div class="form-group">
            <FormInput
              v-model="name"
              name="name"
              :placeholder="vehicle?.model?.name"
              translation-key="name"
              :no-label="true"
            />
          </div>
        </div>
        <div class="col-12 col-md-6">
          <div class="form-group">
            <FormInput
              v-model="serial"
              name="serial"
              :placeholder="t('placeholders.vehicle.serial')"
              translation-key="vehicle.serial"
              :no-label="true"
            />
          </div>
        </div>
        <div class="col-12 col-md-6">
          <FormToggle
            v-model="nameVisible"
            name="nameVisible"
            :label="t('labels.vehicle.nameVisible')"
          />
        </div>
      </div>
      <AlternativeNamesInput
        v-model="alternativeNames"
        name="alternativeNames"
        :current-name="name"
        @use-name="useName"
      />
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :loading="submitting"
          size="large"
          data-test="vehicle-save"
          :inline="true"
          @click="onSubmit"
        >
          {{ t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
