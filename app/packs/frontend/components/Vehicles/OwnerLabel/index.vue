<template>
  <div class="owner">
    <template v-if="usernames.length">
      {{ $t('labels.vehicle.owner') }}

      <Btn :href="`/hangar/${firstOwner}`" variant="link" :text-inline="true">
        {{ firstOwner }}
      </Btn>
      <template v-if="usernames.length > 1">
        {{ $t('labels.and') }}
        <Btn
          variant="link"
          :text-inline="true"
          class="owner-more-action"
          @click.native="openOwnersModal"
        >
          {{ $t('actions.fleet.showOwners') }}
        </Btn>
      </template>
    </template>
    <template v-else>
      {{ $t('labels.vehicle.owner') }}
      <Btn :href="`/hangar/${owner}`" variant="link" :text-inline="true">
        {{ owner }}
      </Btn>
    </template>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import { uniq as uniqArray } from 'frontend/utils/Array'

@Component<ModelPanel>({
  components: {
    Btn,
  },
})
export default class ModelPanel extends Vue {
  @Prop({ default: null }) owner: string | null

  @Prop({
    default() {
      return []
    },
  })
  vehicles: Vehicle[]

  get firstOwner() {
    if (this.usernames.length > 0) {
      return this.usernames[0]
    }

    return null
  }

  get usernames() {
    return this.vehicles
      .map(vehicle => vehicle.username)
      .sort()
      .filter(uniqArray)
  }

  openOwnersModal() {
    this.$comlink.$emit('open-modal', {
      component: () => import('frontend/components/Vehicles/OwnersModal'),
      props: {
        vehicles: this.vehicles,
      },
    })
  }
}
</script>
