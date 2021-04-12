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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import Panel from 'frontend/core/components/Panel'
import MembersListHead from './MembersListHead'
import MembersListItem from './MembersListItem'

@Component<MembersList>({
  components: {
    Panel,
    MembersListHead,
    MembersListItem,
  },
})
export default class Memberslist extends Vue {
  @Prop({ required: true }) members: Member[]

  @Prop({ required: true }) role: string

  @Getter('currentUser', { namespace: 'session' }) currentUser

  get isAdmin() {
    return this.role === 'admin'
  }

  canEdit(member) {
    if (member && this.currentUser) {
      return this.isAdmin && member.username !== this.currentUser.username
    }

    return false
  }
}
</script>
