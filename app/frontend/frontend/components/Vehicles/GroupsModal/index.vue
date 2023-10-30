<template>
  <Modal
    v-if="vehicle && form"
    :title="$t('headlines.editGroups', { vehicle: vehicle.model.name })"
  >
    <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
      <form :id="`vehicle-${vehicle.id}`" @submit.prevent="handleSubmit(save)">
        <div v-if="hangarGroups.length" class="row">
          <div
            v-for="group in hangarGroups"
            :key="group.id"
            class="col-12 col-md-6"
          >
            <Checkbox
              :label="group.name"
              :value="selected(group.id)"
              @input="changeGroup(group)"
            />
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
import hangarGroupsCollection from "@/frontend/api/collections/HangarGroups";

type HangarGroupFormData = {
  id: number;
  name: string;
  selected: boolean;
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
export default class VehicleGroupsModal extends Vue {
  @Prop({ required: true }) vehicle: Vehicle;

  submitting = false;

  form: HangarGroupFormData | null = null;

  get hangarGroups() {
    return hangarGroupsCollection.records;
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
      hangarGroupIds: this.vehicle.hangarGroupIds,
    };
  }

  selected(groupId) {
    return (this.form.hangarGroupIds || []).includes(groupId);
  }

  changeGroup(group) {
    if (this.form.hangarGroupIds.includes(group.id)) {
      const index = this.form.hangarGroupIds.findIndex(
        (groupId) => groupId === group.id,
      );
      if (index > -1) {
        this.form.hangarGroupIds.splice(index, 1);
      }
    } else {
      this.form.hangarGroupIds.push(group.id);
    }
  }

  async save() {
    this.submitting = true;

    const response = await vehiclesCollection.update(
      this.vehicle.id,
      this.form,
    );

    this.submitting = false;

    if (!response.error) {
      this.$comlink.$emit("close-modal");
    }
  }
}
</script>
