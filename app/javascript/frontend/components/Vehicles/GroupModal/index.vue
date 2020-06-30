<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal ref="modal" :title="title" :visible="visible">
      <form :id="`group-${id}`" @submit.prevent="handleSubmit(save)">
        <div class="row">
          <div class="col-12 col-md-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="group-name"
              rules="required|alpha_dash"
              :name="$t('labels.hangarGroup.name')"
              :slim="true"
            >
              <FormInput
                id="group-name"
                v-model="form.name"
                translation-key="name"
                :error="errors[0]"
                :no-label="true"
              />
            </ValidationProvider>
          </div>
          <div class="col-12 col-md-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="color"
              rules="required"
              :name="$t('labels.hangarGroup.color')"
              :immediate="true"
              :slim="true"
            >
              <FormInput
                id="vehicle-color"
                v-model="form.color"
                translation-key="color"
                :no-label="true"
                :error="errors[0]"
                type="color"
              />
            </ValidationProvider>
          </div>
        </div>
      </form>
      <template #footer>
        <div class="float-sm-right">
          <Btn
            v-if="group"
            :disabled="deleting ? 'disabled' : null"
            :inline="true"
            @click.native="remove"
          >
            <i class="fal fa-trash" />
          </Btn>
          <Btn
            :form="`group-${id}`"
            :loading="submitting"
            type="submit"
            size="large"
            :inline="true"
          >
            {{ $t('actions.save') }}
          </Btn>
        </div>
      </template>
    </Modal>
  </ValidationObserver>
</template>

<script>
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import { displayAlert, displayConfirm } from 'frontend/lib/Noty'

export default {
  components: {
    Modal,
    Btn,
    FormInput,
  },

  props: {
    group: {
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
      deleting: false,
      form: {
        name: this.group.name,
        color: this.group.color,
      },
    }
  },

  computed: {
    title() {
      if (this.group.id) {
        return this.$t('headlines.hangarGroup.edit')
      }

      return this.$t('headlines.hangarGroup.create')
    },

    id() {
      return this.group.id || 'new'
    },
  },

  watch: {
    group() {
      this.form = {
        name: this.group.name,
        color: this.group.color,
      }
    },
  },

  methods: {
    open() {
      this.$refs.modal.open()
    },

    remove() {
      this.deleting = true

      displayConfirm({
        text: this.$t('messages.confirm.hangarGroup.destroy'),
        onConfirm: () => {
          this.destroy()
        },
        onClose: () => {
          this.deleting = false
        },
      })
    },

    async destroy() {
      const response = await this.$api.destroy(`hangar-groups/${this.group.id}`)

      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('hangarGroupDelete', response.data)
      } else {
        this.deleting = false
      }
    },

    async save() {
      this.submitting = true

      if (this.group.id) {
        this.update()
      } else {
        this.create()
      }
    },

    async update() {
      const response = await this.$api.put(
        `hangar-groups/${this.group.id}`,
        this.form,
      )

      this.submitting = false

      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('hangarGroupSave', response.data)
      } else {
        displayAlert({
          text: response.error.response.data.message,
        })
      }
    },

    async create() {
      const response = await this.$api.post('hangar-groups', this.form)

      this.submitting = false

      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('hangarGroupSave', response.data)
      } else {
        displayAlert({
          text: response.error.response.data.message,
        })
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
