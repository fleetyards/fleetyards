<template>
  <Modal
    ref="modal"
    :title="t('headlines.rsiVerification')"
    :visible="visible"
    :on-close="onClose"
  >
    <div class="row">
      <div class="col-xs-12">
        <br>
        <p v-html="t('texts.rsiVerification.instructions')" />
        <div class="input-group-flex">
          <input
            :value="verificationText"
            class="form-control text-center disabled-clean"
            disabled
          >
          <Btn
            small
            @click.native="copyToken"
          >
            <i class="fa fa-copy" />
          </Btn>
        </div>
        <p v-html="t('texts.rsiVerification.subline')" />
      </div>
    </div>
    <Loader
      v-if="submitting"
      fixed />
    <template slot="footer">
      <div class="pull-right">
        <Btn
          :disabled="submitting"
          large
          @click.native="verify"
        >
          {{ t('actions.verify') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/components/Btn'
import { success, alert } from 'frontend/lib/Noty'
import Loader from 'frontend/components/Loader'

export default {
  components: {
    Modal,
    Btn,
    Loader,
  },
  mixins: [I18n],
  props: {
    verificationText: {
      type: String,
      default: '',
    },
    visible: {
      type: Boolean,
      default: false,
    },
    onClose: {
      type: Function,
      default: null,
    },
  },
  data() {
    return {
      submitting: false,
    }
  },
  methods: {
    open() {
      this.$refs.modal.open()
    },
    copyToken() {
      this.$copyText(this.verificationText).then(() => {
        success(this.t('messages.copy.success'))
      }, () => {
        alert(this.t('messages.copy.failure'))
      })
    },
    verify() {
      this.submitting = true
      this.$api.post('users/finish-rsi-verification', {}, (args) => {
        this.submitting = false
        if (!args.error) {
          success(this.t('messages.rsiVerification.success'))
          this.$refs.modal.close()
        } else {
          alert(this.t('messages.rsiVerification.failure'))
        }
      })
    },
  },
}
</script>
