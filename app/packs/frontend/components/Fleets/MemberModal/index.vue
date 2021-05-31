<template>
  <ValidationObserver v-slot="{ handleSubmit }" slim>
    <Modal v-if="fleet && form" :title="$t('headlines.fleets.inviteMember')">
      <form
        :id="`fleet-member-${fleet.id}`"
        @submit.prevent="handleSubmit(save)"
      >
        <div class="row">
          <div class="col-12">
            <ValidationProvider
              v-slot="{ errors }"
              vid="username"
              rules="required|alpha_dash|user"
              :name="$t('labels.username')"
              :slim="true"
            >
              <FormInput
                id="username"
                v-model="form.username"
                :error="errors[0]"
                :no-label="true"
                :autofocus="true"
              />
            </ValidationProvider>
          </div>
        </div>
      </form>
      <template #footer>
        <div class="float-sm-right">
          <Btn
            :form="`fleet-member-${fleet.id}`"
            :loading="submitting"
            type="submit"
            size="large"
            :inline="true"
          >
            {{ $t('actions.fleet.members.invite') }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import FormInput from 'frontend/core/components/Form/FormInput'
import Btn from 'frontend/core/components/Btn'
import memberCollection from 'frontend/api/collections/FleetMembers'
import { displayAlert } from 'frontend/lib/Noty'

@Component<MemberModal>({
  components: {
    Modal,
    FormInput,
    Btn,
  },
})
export default class MemberModal extends Vue {
  @Prop({ required: true }) fleet: Fleet

  submitting: boolean = false

  form: FleetMemberForm | null = null

  mounted() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      username: null,
    }
  }

  async save() {
    this.submitting = true

    const response = await memberCollection.create(this.fleet.slug, this.form)

    this.submitting = false

    if (!response.error) {
      this.$comlink.$emit('fleet-member-invited', response.data)
      this.$comlink.$emit('close-modal')
    } else {
      displayAlert({
        text: this.$t(response.error),
      })
    }
  }
}
</script>
