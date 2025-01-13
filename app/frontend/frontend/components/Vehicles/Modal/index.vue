<script lang="ts">
export default {
  name: "VehicleEditModal",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import FilterGroup from "@/shared/components/base/FilterGroup/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/shared/composables/useI18n";
import { type VehicleUpdateInput, type Vehicle } from "@/services/fyApi";
import { useVehicleQueries } from "@/frontend/composables/useVehicleQueries";
import { useModelQueries } from "@/frontend/composables/useModelQueries";
import { BtnSizesEnum, BtnTypesEnum } from "@/shared/components/base/Btn/types";

type Props = {
  vehicle: Vehicle;
  wishlist: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();

const submitting = ref(false);

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
const [modelPaintId, modelPaintIdProps] = defineField("modelPaintId");
const [boughtVia, boughtViaProps] = defineField("boughtVia");

const vehicleName = computed(() => {
  if (props.vehicle.name) {
    return props.vehicle.name;
  }

  return props.vehicle.model.name;
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

const { updateMutation, boughtViaFiltersQuery } = useVehicleQueries(
  props.vehicle,
);

const mutation = updateMutation();

const onSubmit = handleSubmit(async (values) => {
  mutation.mutate(values, {
    onSuccess: () => {
      comlink.emit("close-modal");
    },
  });
});

const { data: boughtViaFilters } = boughtViaFiltersQuery();

const { paintsFilterQuery, paintsFilterFormatter } = useModelQueries(
  props.vehicle.model.slug,
);
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
        <span v-html="vehicle.model.manufacturer?.name" />
        {{ vehicle.model.name }}
      </small>
    </template>

    <form :id="`vehicle-${vehicle.id}`" @submit.prevent="onSubmit">
      <div class="row">
        <div class="col-12 col-md-6">
          <FormCheckbox
            v-if="!wishlist"
            v-model="flagship"
            v-bind="flagshipProps"
            name="flagship"
            :label="t('labels.vehicle.flagship')"
          />
        </div>
        <div v-if="vehicle && vehicle.model.hasPaints" class="col-12 col-md-6">
          <div class="form-group">
            <FilterGroup
              :key="`paints-new-${vehicle.model.id}`"
              v-model="modelPaintId"
              v-bind="modelPaintIdProps"
              :label="t('labels.findModel')"
              :query-fn="paintsFilterQuery"
              :query-response-formatter="paintsFilterFormatter"
              name="modelPaintId"
              :big-icon="true"
              :nullable="true"
            />
          </div>
        </div>
        <div class="col-12">
          <hr class="dark slim-spacer" />
        </div>
        <div class="col-12 col-md-6">
          <FormCheckbox
            v-if="wishlist"
            v-model="saleNotify"
            v-bind="saleNotifyProps"
            name="saleNotify"
            :label="t('labels.vehicle.saleNotify')"
          />
          <FormCheckbox
            v-model="publicVisible"
            v-bind="publicVisibleProps"
            name="public"
            :label="t('labels.vehicle.public')"
          />
        </div>
        <div class="col-12 col-md-6">
          <div class="form-group">
            <FilterGroup
              :key="`bought-via-${vehicle.model.id}`"
              v-model="boughtVia"
              v-bind="boughtViaProps"
              :options="boughtViaFilters"
              :label="t('labels.vehicle.boughtViaSelect.label')"
              name="boughtVia"
              :nullable="false"
            />
          </div>
        </div>
      </div>
    </form>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :form="`vehicle-${vehicle.id}`"
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
