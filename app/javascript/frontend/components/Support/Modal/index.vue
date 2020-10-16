<template>
  <Modal :title="$t('headlines.support')">
    <div class="support-body">
      <br />
      <div class="row">
        <div class="col-12">
          <p v-html="$t('texts.support.info')" />
        </div>
      </div>
      <br />
      <div class="row">
        <div class="col-12">
          <p v-html="$t('texts.support.code', { code: 'STAR-5F32-SJZ4' })" />
        </div>
      </div>
      <br />
      <p>
        {{ $t('labels.supportUs') }}
      </p>
      <div class="page-actions page-actions-center">
        <Btn
          href="https://paypal.me/pools/c/83jQLadz60"
          size="large"
          :inline="true"
        >
          <i class="fab fa-paypal" />
          PayPal
        </Btn>
        {{ $t('labels.or') }}&nbsp;&nbsp;
        <Btn
          href="https://www.patreon.com/fleetyards"
          size="large"
          :inline="true"
        >
          <i class="fab fa-patreon" />
          Patreon
        </Btn>
      </div>
    </div>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'

@Component<SupportModal>({
  components: {
    Modal,
    Btn,
  },
})
export default class SupportModal extends Vue {}
</script>
