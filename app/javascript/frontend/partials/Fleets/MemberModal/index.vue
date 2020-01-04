<template>
  <Modal
    v-if="fleet"
    ref="modal"
    :title="$t('headlines.fleets.inviteMember')"
    :visible="visible"
  >
    <form
      :id="`fleet-member-${fleet.id}`"
      @submit.prevent="save"
    >
      <div class="row">
        <div class="col-xs-12">
          <div
            :class="{'has-error has-feedback': errors.has('username')}"
            class="form-group"
          >
            <label for="username">
              {{ $t('labels.username') }}
            </label>
            <input
              id="username"
              v-model="form.username"
              v-tooltip.right="errors.first('username')"
              v-validate="'required|alpha_dash|user'"
              data-test="username"
              :data-vv-as="$t('labels.username')"
              :placeholder="$t('labels.username')"
              name="username"
              type="text"
              class="form-control"
              autofocus
            >
            <span
              v-show="errors.has('username')"
              class="form-control-feedback"
            >
              <i
                :title="errors.first('username')"
                class="fal fa-exclamation-triangle"
              />
            </span>
          </div>
        </div>
      </div>
    </form>
    <template #footer>
      <div class="pull-right">
        <Btn
          :form="`fleet-member-${fleet.id}`"
          :loading="submitting"
          type="submit"
          size="large"
          inline
        >
          {{ $t('actions.fleet.members.invite') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Modal,
    Btn,
  },

  props: {
    fleet: {
      type: Object,
      required: true,
    },

    visible: {
      type: Boolean,
      default: false,
    },
  },

  data() {
    return {
      submitting: false,
      form: {
        username: null,
      },
    }
  },

  methods: {
    open() {
      this.form = {
        username: null,
      }

      this.$nextTick(() => {
        this.$refs.modal.open()
      })
    },

    async save() {
      const result = await this.$validator.validateAll()
      if (!result) {
        this.$alert({
          text: this.$t('messages.fleet.invites.create.failure'),
        })
        return
      }

      this.submitting = true

      const response = await this.$api.post(`fleets/${this.fleet.slug}/members`, this.form)

      this.submitting = false

      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('fleetMemberInvited', response.data)
      }
    },
  },
}
</script>
