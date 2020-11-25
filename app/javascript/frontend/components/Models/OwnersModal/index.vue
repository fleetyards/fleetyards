<template>
  <Modal :title="$t('headlines.fleets.owners')">
    <ul class="list-unstyled">
      <li v-for="username in usernames" :key="username">
        <Btn :href="`/hangar/${username}`" variant="link">
          {{ username }}
        </Btn>
      </li>
    </ul>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Btn from 'frontend/core/components/Btn'
import Modal from 'frontend/core/components/AppModal/Modal'

@Component<OwnersModal>({
  components: {
    Btn,
    Modal,
  },
})
export default class OwnersModal extends Vue {
  @Prop({ required: true }) usernames: string[]
}
</script>
