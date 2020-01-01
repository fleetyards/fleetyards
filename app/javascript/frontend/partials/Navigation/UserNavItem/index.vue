<template>
  <NavItem
    v-if="currentUser"
    :item="item"
    :slim="slim"
    class="user-menu"
    :class="{
      'user-menu-slim': slim,
    }"
  >
    <Avatar
      :avatar="currentUser.avatar"
      size="small"
    />
    <span
      v-if="!slim"
      class="username"
    >
      {{ currentUser.username }}
    </span>
  </NavItem>
</template>

<script>
import { mapGetters } from 'vuex'

import NavItem from 'frontend/partials/Navigation/NavItem'
import Avatar from 'frontend/components/Avatar'


export default {
  name: 'FleetNavItem',

  components: {
    NavItem,
    Avatar,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },

    slim: {
      type: Boolean,
      required: false,
    },
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
