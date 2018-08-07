<template>
  <Modal
    ref="modal"
    :title="t('headlines.newFleet')"
    :visible="visible"
  >
    <form
      id="fleet-form"
      @submit.prevent="submit"
    >
      <div class="row">
        <div class="col-xs-12">
          <div
            :class="{'has-error has-feedback': errors.has('sid')}"
            class="form-group"
          >
            <input
              v-tooltip.bottom-end="errors.first('sid')"
              v-validate="'required|alpha_dash|org'"
              id="sid"
              v-model="sid"
              :placeholder="t('placeholders.fleet.sid')"
              :data-vv-as="t('labels.fleet.sid')"
              name="sid"
              type="text"
              class="form-control"
              @input="changeSID"
            >
            <span
              v-show="errors.has('sid')"
              class="form-control-feedback"
            >
              <i
                :title="errors.first('sid')"
                class="fal fa-exclamation-triangle"
              />
            </span>
          </div>
        </div>
      </div>
    </form>
    <div class="row">
      <div class="col-xs-12 fleet-preview">
        <transition
          name="fade-list"
          appear>
          <FleetPanel
            v-if="org"
            :fleet="org"
          />
        </transition>
        <Loader
          v-if="loading"
          class="fleet-modal-loader"
        />
      </div>
    </div>
    <template slot="footer">
      <SubmitButton
        :loading="submitting"
        form="fleet-form"
        class="pull-right"
      >
        {{ t('actions.save') }}
      </SubmitButton>
    </template>
  </Modal>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import SubmitButton from 'frontend/components/SubmitButton'
import Modal from 'frontend/components/Modal'
import { alert } from 'frontend/lib/Noty'
import Loader from 'frontend/components/Loader'
import FleetPanel from 'frontend/partials/Fleets/Panel'

export default {
  components: {
    SubmitButton,
    Modal,
    Loader,
    FleetPanel,
  },
  mixins: [I18n],
  props: {
    visible: {
      type: Boolean,
      default: false,
    },
    callback: {
      type: Function,
      required: true,
    },
  },
  data() {
    return {
      org: null,
      submitting: false,
      sid: null,
      loading: false,
      fetchTimeout: null,
    }
  },
  methods: {
    open() {
      this.$refs.modal.open()
      this.sid = ''
      this.org = null
    },
    changeSID() {
      if (this.fetchTimeout) {
        clearTimeout(this.fetchTimeout)
      }
      this.fetchTimeout = setTimeout(() => {
        this.fetchOrg()
      }, 300)
    },
    fetchOrg() {
      this.loading = true
      this.$api.get(`rsi/orgs/${this.sid}`, {}, (args) => {
        this.loading = false
        if (!args.error) {
          this.org = args.data
        }
      })
    },
    submit() {
      this.$validator.validateAll().then((result) => {
        if (!result) {
          return
        }
        this.submitting = true
        this.$api.post('fleets', { sid: this.sid }, (args) => {
          this.submitting = false
          if (!args.error) {
            this.callback()
            this.$refs.modal.close()
          } else {
            alert(this.t('messages.fleet.create.failure'))
          }
        })
      })
    },
  },
}
</script>

<style lang="scss" scoped>
  @import "./styles/index";
</style>
