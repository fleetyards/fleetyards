<template>
  <Modal :title="$t('headlines.fleets.owners')">
    <div class="row">
      <div class="col-12 col-md-6" v-for="user in users" :key="user.username">
        <Btn :href="`/hangar/${user.username}`" :block="true">
          <div class="user-item">
            <Avatar :avatar="user.avatar" size="small" />
            <span class="user-item-username">{{ user.username }}</span>
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

@Component<OwnersModal>({
  components: {
    Btn,
    Modal,
    Avatar,
  },
})
export default class OwnersModal extends Vue {
  @Prop({ required: true }) users: User[]
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
