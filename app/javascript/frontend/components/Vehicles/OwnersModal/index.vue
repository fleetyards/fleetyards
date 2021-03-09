<template>
  <Modal :title="$t('headlines.fleets.owners')">
    <div class="row">
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
              </span>
            </span>
          </div>
        </Btn>
      </div>
    </div>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import Modal from 'frontend/core/components/AppModal/Modal'
import Avatar from 'frontend/core/components/Avatar'
import { sortBy } from 'frontend/lib/Helpers'

@Component<OwnersModal>({
  components: {
    Btn,
    Modal,
    Avatar,
  },
})
export default class OwnersModal extends Vue {
  @Prop({ required: true }) vehicles: Vehicle[]

  get sortedVehicles() {
    return sortBy(this.vehicles, 'username')
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
