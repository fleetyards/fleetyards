<template>
  <ValidationObserver v-slot="{ handleSubmit }" slim>
    <Modal
      v-if="fleet"
      ref="modal"
      :title="$t('headlines.fleets.inviteMember')"
      :visible="visible"
    >
      <form
        :id="`fleet-member-${fleet.id}`"
        @submit.prevent="handleSubmit(save)"
      >
        <div class="row">
          <div class="col-xs-12">
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|user"
              :name="$t('labels.username')"
              slim
            >
              <FormInput
                id="username"
                v-model="form.username"
                :error="errors[0]"
                autofocus
              />
            </ValidationProvider>
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
  </ValidationObserver>
</template>

<script>
import Modal from 'frontend/components/Modal'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'

export default {
  components: {
    Modal,
    FormInput,
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
      this.submitting = true

      const response = await this.$api.post(
        `fleets/${this.fleet.slug}/members`,
        this.form,
      )

      this.submitting = false

      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('fleetMemberInvited', response.data)
      }
    },
  },
}
</script>
