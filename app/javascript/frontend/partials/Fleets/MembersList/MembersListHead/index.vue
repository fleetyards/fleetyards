<template>
  <div class="fade-list-item col-xs-12 flex-list-heading">
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { sortByToggle } from 'frontend/utils/Sorting'

@Component<MembersListHead>()
export default class MembersListHead extends Vue {
  @Prop({ default: false }) editable: boolean

  sortByToggle(field) {
    return sortByToggle(field, this.$route)
  }
}
</script>
