<template>
  <Panel v-if="members.length">
    <transition-group
      name="fade"
      class="flex-list flex-list-users"
      tag="div"
      :appear="true"
    >
      <MembersListHead key="heading" :editable="isAdmin" />
      <MembersListItem
        v-for="(member, index) in members"
        :key="`members-${index}`"
        :member="member"
        :editable="isAdmin"
        :editable-member="canEdit(member)"
      />
    </transition-group>
  </Panel>
</template>

<script>
import { mapGetters } from 'vuex'
import Panel from '@/frontend/core/components/Panel/index.vue'
import MembersListHead from './MembersListHead/index.vue'
import MembersListItem from './MembersListItem/index.vue'

export default {
  name: 'MembersList',

  components: {
    MembersListHead,
    MembersListItem,
    Panel,
  },

  props: {
    members: {
      required: true,
      type: Array,
    },

    role: {
      required: true,
      type: String,
    },
  },

  computed: {
    ...mapGetters('session', ['currentUser']),

    isAdmin() {
      return this.role === 'admin'
    },
  },

  methods: {
    canEdit(member) {
      if (member && this.currentUser) {
        return this.isAdmin && member.username !== this.currentUser.username
      }

      return false
    },
  },
}
</script>
