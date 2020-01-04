<template>
  <Modal
    ref="modal"
    :title="title"
    :visible="visible"
  >
    <form
      :id="`group-${id}`"
      @submit.prevent="save"
    >
      <div class="row">
        <div class="col-xs-12 col-sm-6">
          <div
            :class="{'has-error has-feedback': errors.has('name')}"
            class="form-group"
          >
            <input
              v-model="form.name"
              v-tooltip.right="errors.first('name')"
              v-validate="'required'"
              :data-vv-as="$t('labels.hangarGroup.name')"
              :placeholder="$t('labels.hangarGroup.name')"
              name="name"
              type="text"
              class="form-control"
            >
            <span
              v-show="errors.has('name')"
              class="form-control-feedback"
            >
              <i class="fal fa-exclamation-triangle" />
            </span>
          </div>
        </div>
        <div class="col-xs-12 col-sm-8 col-sm-offset-2 text-center">
          <div
            :class="{'has-error has-feedback': errors.has('color')}"
            class="form-group"
          >
            <Swatches
              v-model="form.color"
              v-tooltip.right="errors.first('color')"
              v-validate="'required'"
              :data-vv-as="$t('labels.hangarGroup.color')"
              name="color"
              colors="material-dark"
              shapes="circles"
              swatch-size="24"
              background-color="transparent"
              inline
            />
          </div>
        </div>
      </div>
    </form>
    <template #footer>
      <div class="pull-right">
        <Btn
          v-if="group"
          :disabled="deleting ? 'disabled' : null"
          inline
          @click.native="remove"
        >
          <i class="fal fa-trash" />
        </Btn>
        <Btn
          :form="`group-${id}`"
          :loading="submitting"
          type="submit"
          size="large"
          inline
        >
          {{ $t('actions.save') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script>
import Modal from 'frontend/components/Modal'
import Btn from 'frontend/components/Btn'
import Swatches from 'vue-swatches'
import 'vue-swatches/dist/vue-swatches.min.css'

export default {
  components: {
    Modal,
    Btn,
    Swatches,
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
      return (this.group.id || 'new')
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
      this.$confirm({
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
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      if (this.group.id) {
        this.update()
      } else {
        this.create()
      }
    },
    async update() {
      const response = await this.$api.put(`hangar-groups/${this.group.id}`, this.form)
      this.submitting = false
      if (!response.error) {
        this.$refs.modal.close()
        this.$comlink.$emit('hangarGroupSave', response.data)
      } else {
        this.$alert({
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
        this.$alert({
          text: response.error.response.data.message,
        })
      }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
