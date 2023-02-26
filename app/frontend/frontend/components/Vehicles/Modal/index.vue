<template>
  <Modal v-if="vehicle && form">
    <template #title>
      <span>{{ $t("headlines.editMyVehicle", { vehicle: vehicleName }) }}</span>
      <small v-if="vehicle.serial" class="text-muted">
        {{ vehicle.serial }}
      </small>
      <template v-if="vehicle.name">
        <br />

        <small class="text-muted">
          <span v-html="vehicle.model.manufacturer.name" />
          {{ vehicle.model.name }}
        </small>
      </template>
    </template>

    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div class="row">
          <div class="col-12 col-md-6">
            <Checkbox
              v-if="!wishlist"
              id="flagship"
              v-model="form.flagship"
              :label="$t('labels.vehicle.flagship')"
            />
          </div>
          <div
            v-if="vehicle && vehicle.model.hasPaints"
            class="col-12 col-md-6"
          >
            <div class="form-group">
              <FilterGroup
                :key="`paints-${vehicle.model.id}`"
                v-model="form.modelPaintId"
                translation-key="vehicle.modelPaintSelect"
                :fetch-path="`models/${vehicle.model.slug}/paints`"
                name="modelPaintId"
                value-attr="id"
                icon-attr="storeImageSmall"
                :big-icon="true"
                :nullable="true"
                :no-label="true"
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
              :label="$t('labels.vehicle.saleNotify')"
            />
            <Checkbox
              id="public"
              v-model="form.public"
              :label="$t('labels.vehicle.public')"
            />
          </div>
          <div class="col-12 col-md-6">
            <div class="form-group">
              <ValidationProvider
                v-slot="{ errors }"
                vid="boughtVia"
                rules="required"
                :name="$t('labels.vehicle.boughtVia')"
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
          {{ $t("actions.save") }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop, Watch } from "vue-property-decorator";
import Modal from "@/frontend/core/components/AppModal/Inner/index.vue";
import FormInput from "@/frontend/core/components/Form/FormInput/index.vue";
import FilterGroup from "@/frontend/core/components/Form/FilterGroup/index.vue";
import Checkbox from "@/frontend/core/components/Form/Checkbox/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";

type VehicleFormData = {
  flagship: boolean;
  saleNotify: boolean;
  public: boolean;
  boughtVia: string;
  modelPaintId?: string;
};

@Component<VehicleModal>({
  components: {
    Modal,
    Checkbox,
    FormInput,
    FilterGroup,
    Btn,
  },
})
export default class VehicleModal extends Vue {
  @Prop({ required: true }) vehicle!: Vehicle;

  @Prop({ default: false }) wishlist!: boolean;

  submitting = false;

  form: VehicleFormData | null = null;

  get vehicleName() {
    if (this.vehicle && this.vehicle.name) {
      return this.vehicle.name;
    }

    return this.vehicle.model.name;
  }

  mounted() {
    this.setupForm();
  }

  @Watch("vehicle")
  onVehicleChange() {
    this.setupForm();
  }

  setupForm() {
    this.form = {
      flagship: this.vehicle.flagship,
      public: this.vehicle.public,
      saleNotify: this.vehicle.saleNotify,
      modelPaintId: this.vehicle.paint?.id,
      boughtVia: this.vehicle.boughtVia,
    };
  }

  async save() {
    if (!this.form) {
      return;
    }

    this.submitting = true;

    const response = await vehiclesCollection.update(
      this.vehicle.id,
      this.form
    );

    this.submitting = false;

    if (!response.error) {
      this.$comlink.$emit("close-modal");
    }
  }
}
</script>
