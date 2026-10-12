<script lang="ts">
export default {
  name: "VehicleEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import BaseSelect from "@/shared/components/base/Select/index.vue";
import VehiclePaintPicker from "@/frontend/components/Vehicles/PaintPicker/index.vue";
import FormToggle from "@/shared/components/base/FormToggle/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import {
  useVehicleBoughtViaFilters as useVehicleBoughtViaFiltersQuery,
  type VehicleUpdateInput,
  type Vehicle,
} from "@/services/fyApi";
import { useVehicleMutations } from "@/frontend/composables/useVehicleMutations";
import { BtnTypesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  vehicle: Vehicle;
  wishlist: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();

const initialValues = ref<VehicleUpdateInput>({
  flagship: props.vehicle.flagship,
  public: props.vehicle.public,
  saleNotify: props.vehicle.saleNotify,
  modelPaintId: props.vehicle.paint?.id,
  boughtVia: props.vehicle.boughtVia,
});

const { defineField, handleSubmit } = useForm({
  initialValues: initialValues.value,
});

const [flagship, flagshipProps] = defineField("flagship");
const [publicVisible, publicVisibleProps] = defineField("public");
const [saleNotify, saleNotifyProps] = defineField("saleNotify");
const [modelPaintId] = defineField("modelPaintId");
const [boughtVia, boughtViaProps] = defineField("boughtVia");

const vehicleName = computed(() => {
  if (props.vehicle.name) {
    return props.vehicle.name;
  }

  return props.vehicle?.model?.name;
});

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
    flagship: props.vehicle.flagship,
    public: props.vehicle.public,
    saleNotify: props.vehicle.saleNotify,
    modelPaintId: props.vehicle.paint?.id,
    boughtVia: props.vehicle.boughtVia,
  };
};

const comlink = useComlink();

const { useUpdateMutation } = useVehicleMutations();

const vehicle = computed(() => props.vehicle);

const { mutateAsync, isPending: submitting } = useUpdateMutation(vehicle);

const onSubmit = handleSubmit(async (values) => {
  await mutateAsync({
    id: props.vehicle.id,
    data: values,
  }).then(() => {
    comlink.emit("close-modal");
  });
});

const { data: boughtViaFilters } = useVehicleBoughtViaFiltersQuery();

// There is no pledge store to have bought an in-game-only ship from, and the
// server rewrites the value anyway -- offering the choice would only let
// someone pick an answer that never survives the save.
const boughtViaOptions = computed(() => {
  if (!props.vehicle.model?.ingameOnly) {
    return boughtViaFilters.value;
  }

  return (boughtViaFilters.value || []).filter(
    (option) => option.value === "ingame",
  );
});
</script>

<template>
  <Modal v-if="vehicle">
    <template #title>
      <span>{{ t("headlines.editMyVehicle", { vehicle: vehicleName }) }}</span>
      <small v-if="vehicle.serial" class="text-muted">
        {{ vehicle.serial }}
      </small>
      <br />

      <small class="text-muted">
        <!-- eslint-disable-next-line vue/no-v-html -->
        <span v-html="vehicle.model?.manufacturer?.name" />
        {{ vehicle.model?.name }}
      </small>
    </template>

    <form :id="`vehicle-edit-${vehicle.id}`" @submit.prevent="onSubmit">
      <VehiclePaintPicker
        v-if="vehicle?.model?.hasPaints"
        v-model="modelPaintId"
        :model-slug="vehicle.model.slug"
        :default-image="vehicle.model.media.storeImage?.smallUrl"
      />
      <div class="row">
        <div class="col-12 col-md-6">
          <FormToggle
            v-if="!wishlist"
            v-model="flagship"
            v-bind="flagshipProps"
            name="flagship"
            :label="t('labels.vehicle.flagship')"
          />
        </div>
      </div>
      <!--
        A row per pair, rather than four half-columns in one. The paints picker
        is conditional, and without it the columns reflowed: the toggles below
        ended up beside the other toggle instead of the field they are meant to
        line up with, and the field dropped to a line of its own.
      -->
      <div class="row">
        <div class="col-12 col-md-6">
          <FormToggle
            v-if="wishlist"
            v-model="saleNotify"
            v-bind="saleNotifyProps"
            name="saleNotify"
            :label="t('labels.vehicle.saleNotify')"
            align-with-fields
          />
          <FormToggle
            v-model="publicVisible"
            v-bind="publicVisibleProps"
            name="public"
            :label="t('labels.vehicle.public')"
            :align-with-fields="!wishlist"
          />
        </div>
        <div class="col-12 col-md-6">
          <div class="form-group">
            <BaseSelect
              :key="`bought-via-${vehicle.model?.id}`"
              v-model="boughtVia"
              v-bind="boughtViaProps"
              :options="boughtViaOptions"
              :label="t('labels.vehicle.boughtViaSelect.label')"
              name="boughtVia"
              :nullable="false"
            />
          </div>
        </div>
      </div>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        :form="`vehicle-edit-${vehicle.id}`"
        :loading="submitting"
        data-test="vehicle-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>
