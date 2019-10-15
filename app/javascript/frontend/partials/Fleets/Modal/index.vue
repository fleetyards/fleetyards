<template>
  <Modal
    ref="modal"
    :title="$t('headlines.newFleet')"
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
              id="sid"
              v-model="sid"
              v-tooltip.bottom-end="errors.first('sid')"
              v-validate="'required|alpha_dash|org'"
              :placeholder="$t('placeholders.fleet.sid')"
              :data-vv-as="$t('labels.fleet.sid')"
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
          appear
        >
          <FleetPanel
            v-if="org"
            :fleet="org"
          />
        </transition>
        <Loader
          :loading="loading"
          class="fleet-modal-loader"
        />
      </div>
    </div>
    <template #footer>
      <Btn
        :loading="submitting"
        type="submit"
        size="large"
        form="fleet-form"
        class="pull-right"
      >
        {{ $t('actions.save') }}
      </Btn>
    </template>
  </Modal>
</template>

<script>
import Btn from 'frontend/components/Btn'
import Modal from 'frontend/components/Modal'
import Loader from 'frontend/components/Loader'
import FleetPanel from 'frontend/partials/Fleets/Panel'

export default {
  components: {
    Btn,
    Modal,
    Loader,
    FleetPanel,
  },
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
    async fetchOrg() {
      this.loading = true
      const response = await this.$api.get(`rsi/orgs/${this.sid}`, {})
      this.loading = false
      if (!response.error) {
        this.org = response.data
      }
    },
    async submit() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      const response = await this.$api.post('fleets', { sid: this.sid })
      this.submitting = false
      if (!response.error) {
        this.callback()
        this.$refs.modal.close()
      } else {
        let errors = ''
        if (response.error.response && response.error.response.data
          && response.error.response.data.errors) {
          errors = response.error.response.data.errors.join(', ')
        }
        this.$alert({
          text: [
            this.$t('messages.fleet.create.failure'),
            errors,
          ],
        })
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
