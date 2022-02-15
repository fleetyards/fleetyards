<template>
  <div class="fade-list-item col-12 flex-list-heading">
    <div class="flex-list-row">
      <div class="username">
        <router-link :to="sortByToggle('user_username')">
          {{ $t('labels.username') }}
        </router-link>
      </div>
      <div class="rsi-handle">
        <router-link :to="sortByToggle('user_rsi_handle')">
          {{ $t('labels.user.rsiHandle') }}
        </router-link>
      </div>
      <div class="role" />
      <div class="joined">
        {{ $t('labels.fleet.members.invited') }} /
        {{ $t('labels.fleet.members.joined') }}
      </div>
      <div class="links" />
      <div v-if="editable" class="actions actions-3x">
        {{ $t('labels.actions') }}
      </div>
    </div>
  </div>
</template>

<script>
import { sortByToggle } from '@/frontend/utils/Sorting'

export default {
  name: 'MembersListHead',

  props: {
    editable: {
      type: Boolean,
      default: false,
    },
  },

  methods: {
    sortByToggle(field) {
      return sortByToggle(field, this.$route)
    },
  },
}
</script>
