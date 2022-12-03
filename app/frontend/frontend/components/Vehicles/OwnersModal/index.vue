<template>
  <Modal :title="$t('headlines.fleets.owners')">
    <div class="row">
      <div v-if="loading" class="col-12">
        <Loader :loading="loading" :inline="true" />
      </div>
      <template v-else>
        <div
          v-for="vehicle in sortedVehicles"
          :key="vehicle.username"
          class="col-12 col-md-6"
        >
          <Btn :href="`/hangar/${vehicle.username}`" :block="true">
            <div class="user-item">
              <Avatar :avatar="vehicle.userAvatar" size="small" />
              <span class="user-item-username">
                {{ vehicle.username }}
                <span v-if="vehicle.name" class="user-item-ship">
                  {{ vehicle.name }}
                  <span v-if="vehicle.serial" class="user-item-ship-serial">
                    ({{ vehicle.serial }})
                  </span>
                </span>
              </span>
            </div>
          </Btn>
        </div>
      </template>
    </div>
  </Modal>
</template>

<script lang="ts">
import Vue from "vue";
import { Component, Prop } from "vue-property-decorator";
import Btn from "@/frontend/core/components/Btn/index.vue";
import Modal from "@/frontend/core/components/AppModal/Modal/index.vue";
import Avatar from "@/frontend/core/components/Avatar/index.vue";
import { sortBy } from "@/frontend/lib/Helpers";
import { uniqByField as uniqByFieldArray } from "@/frontend/utils/Array";
import { FleetVehiclesCollection } from "@/frontend/api/collections/FleetVehicles";
import Loader from "@/frontend/core/components/Loader/index.vue";

@Component<OwnersModal>({
  components: {
    Btn,
    Modal,
    Avatar,
    Loader,
  },
})
export default class OwnersModal extends Vue {
  @Prop({ required: true }) modelSlug: string;

  @Prop({ required: true }) fleetSlug: string;

  collection: FleetVehiclesCollection = new FleetVehiclesCollection();

  loading = true;

  get sortedVehicles() {
    return sortBy(this.collection.records, "username").filter(
      uniqByFieldArray("username")
    );
  }

  async mounted() {
    await this.collection.findAll({
      slug: this.fleetSlug,
      filters: { modelSlugIn: [this.modelSlug] },
      grouped: false,
      perPage: "all",
    });

    this.loading = false;
  }
}
</script>

<style lang="scss" scoped>
@import "index";
</style>
