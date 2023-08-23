<template>
  <Modal
    v-if="model"
    :title="$t('headlines.addToHangar', { model: model.name })"
  >
    <div class="page-actions page-actions-block">
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-normal"
        @click.native="addToHangar"
      >
        {{ $t("actions.addToHangar") }}
      </Btn>
      <Btn
        :inline="true"
        data-test="add-to-hangar-as-wanted"
        @click.native="addToWishlist"
      >
        {{ $t("actions.addToWishlist") }}
      </Btn>
    </div>
  </Modal>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import { Action } from "vuex-class";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/frontend/core/components/Btn/index.vue";
import { displaySuccess } from "@/frontend/lib/Noty";
import vehiclesCollection from "@/frontend/api/collections/Vehicles";

@Component<AddToHangarModal>({
  components: {
    Modal,
    Btn,
  },
})
export default class AddToHangarModal extends Vue {
  @Prop({ required: true }) model: Model;

  @Action("add", { namespace: "hangar" }) saveToHangar;

  @Action("add", { namespace: "wishlist" }) saveToWishlist;

  async addToWishlist() {
    const success = await vehiclesCollection.create({
      wanted: true,
      modelId: this.model.id,
    });

    if (success) {
      await this.saveToWishlist(this.model.slug);

      displaySuccess({
        text: this.$t("messages.vehicle.addToWishlist.success", {
          model: this.model.name,
        }),
        icon: this.model.storeImageSmall,
      });

      this.$comlink.$emit("close-modal");
    }
  }

  async addToHangar() {
    const success = await vehiclesCollection.create({
      modelId: this.model.id,
    });

    if (success) {
      await this.saveToHangar(this.model.slug);

      displaySuccess({
        text: this.$t("messages.vehicle.add.success", {
          model: this.model.name,
        }),
        icon: this.model.storeImageSmall,
      });

      this.$comlink.$emit("close-modal");
    }
  }
}
</script>
