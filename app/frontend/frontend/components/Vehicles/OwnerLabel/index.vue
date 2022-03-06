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

<script>
import Btn from '@/frontend/core/components/Btn/index.vue'
import { uniq as uniqArray } from '@/frontend/utils/Array'

export default {
  name: 'ModelPanel',
  components: {
    Btn,
  },

  props: {
    owner: {
      type: String,
      default: null,
    },

    vehicles: {
      type: Array,
      default() {
        return []
      },
    },
  },

  computed: {
    firstOwner() {
      if (this.usernames.length > 0) {
        return this.usernames[0]
      }

      return null
    },

    usernames() {
      return this.vehicles
        .map((vehicle) => vehicle.username)
        .sort()
        .filter(uniqArray)
    },
  },

  methods: {
    openOwnersModal() {
      this.$comlink.$emit('open-modal', {
        component: () =>
          import('@/frontend/components/Vehicles/OwnersModal/index.vue'),
        props: {
          vehicles: this.vehicles,
        },
      })
    },
  },
}
</script>
