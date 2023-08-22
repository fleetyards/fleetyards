<template>
  <Modal v-if="vehicle && form">
    <template #title>
      <span>{{ t("headlines.editMyVehicle", { vehicle: vehicleName }) }}</span>
      <small v-if="vehicle.serial" class="text-muted">
        {{ vehicle.serial }}
      </small>
      <br />

      <small class="text-muted">
        <span v-html="vehicle.model.manufacturer.name" />
        {{ vehicle.model.name }}
      </small>
    </template>

    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div class="row">
          <div class="col-12 col-md-6">
            <Checkbox
              v-if="!wishlist"
              id="flagship"
              v-model="form.flagship"
              :label="t('labels.vehicle.flagship')"
            />
          </div>
          <div
            v-if="vehicle && vehicle.model.hasPaints"
            class="col-12 col-md-6"
          >
            <div class="form-group">
              <FilterGroup2
                :key="`paints-new-${vehicle.model.id}`"
                v-model="form.modelPaintId"
                translation-key="vehicle.modelPaintSelect"
                :fetch="fetchPaints"
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
            <Checkbox
              v-if="wishlist"
              id="saleNotify"
              v-model="form.saleNotify"
              :label="t('labels.vehicle.saleNotify')"
            />
            <Checkbox
              id="public"
              v-model="form.public"
              :label="t('labels.vehicle.public')"
            />
          </div>
          <div class="col-12 col-md-6">
            <div class="form-group">
              <ValidationProvider
                v-slot="{ errors }"
                vid="boughtVia"
                rules="required"
                :name="t('labels.vehicle.boughtVia')"
                :slim="true"
              >
                <FilterGroup
                  :key="`bought-via-${vehicle.model.id}`"
                  v-model="form.boughtVia"
                  translation-key="vehicle.boughtViaSelect"
                  fetch-path="vehicles/filters/bought-via"
                  name="boughtVia"
                  :error="errors[0]"
                  :nullable="false"
                />
              </ValidationProvider>
            </div>
          </div>
        </div>
      </form>
    </ValidationObserver>

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

<script lang="ts" setup>
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import FilterGroup2 from "@/frontend/core/components/Form/FilterGroup2/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";
import modelPaintsCollection from "@/frontend/api/collections/ModelPaints";
import { useComlink } from "@/shared/composables/useComlink";
import { useI18n } from "@/frontend/composables/useI18n";

type VehicleFormData = {
  flagship: boolean;
  saleNotify: boolean;
  public: boolean;
  boughtVia: string;
  modelPaintId?: string;
};

type Props = {
  vehicle: Vehicle;
  wishlist: boolean;
};

const props = withDefaults(defineProps<Props>(), {
  wishlist: false,
});

const { t } = useI18n();

const submitting = ref(false);

const form = ref<VehicleFormData | null>(null);

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
  form.value = {
    flagship: props.vehicle.flagship,
    public: props.vehicle.public,
    saleNotify: props.vehicle.saleNotify,
    modelPaintId: props.vehicle.paint?.id,
    boughtVia: props.vehicle.boughtVia,
  };
};

const comlink = useComlink();

const save = async () => {
  if (!form.value) {
    return;
  }

  submitting.value = true;

  const response = await vehiclesCollection.update(
    props.vehicle.id,
    form.value,
  );

  submitting.value = false;

  if (!response.error) {
    comlink.$emit("close-modal");
  }
};

const fetchPaints = async (params?: TFilterGroupParams) => {
  if (!props.vehicle.model.hasPaints) {
    return [];
  }

  const filters: ModelPaintFilters = {
    modelSlugEq: props.vehicle.model.slug,
  };

  if (params?.search) {
    filters.nameCont = params.search;
  } else if (params?.missing) {
    if (Array.isArray(params.missing)) {
      filters.idIn = params.missing;
    } else {
      filters.idEq = params.missing;
    }
  }

  const data = await modelPaintsCollection.findAll({
    filters,
    page: params?.page || 1,
  });

  if (!data) {
    return [];
  }

  return data.map((paint) => ({
    label: paint.name,
    value: paint.id,
    icon: paint.media.storeImage?.small,
  }));
};
</script>

<script lang="ts">
export default {
  name: "VehicleEditModal",
};
</script>
