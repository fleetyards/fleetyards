<template>
  <div>
    <Btn
      size="small"
      class="support-button"
      @click.native="open"
    >
      {{ $t('actions.supportUs') }}
    </Btn>
    <Modal
      ref="modal"
      :title="$t('headlines.support')"
    >
      <div class="support-body">
        <br>
        <div class="row">
          <div class="col-xs-12">
            <p v-html="$t('texts.support.info')" />
          </div>
        </div>
        <br>
        <div class="row">
          <div class="col-xs-12">
            <p v-html="$t('texts.support.code', { code: 'STAR-5F32-SJZ4'})" />
          </div>
        </div>
        <br>
        <Btn
          href="https://paypal.me/pools/c/83jQLadz60"
          size="large"
        >
          <i class="fab fa-paypal" />
          {{ $t('actions.supportUsPaypal') }}
        </Btn>
      </div>
    </modal>
  </div>
</template>

<script>
import Btn from 'frontend/components/Btn'
import Modal from 'frontend/components/Modal'

export default {
  components: {
    Btn,
    Modal,
  },
  data() {
    return {
      visible: false,
    }
  },
  methods: {
    open() {
      this.$refs.modal.open()
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'styles/index.scss';
</style>
