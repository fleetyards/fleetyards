<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="hangarGroup && form" :title="title">
      <form :id="`hangar-group-${id}`" @submit.prevent="handleSubmit(save)">
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
              rules="required|hexColor"
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
                type="text"
              />
            </ValidationProvider>
          </div>
          <div class="col-12 col-md-6">
            <Checkbox
              id="public"
              v-model="form.public"
              :label="$t('labels.hangarGroup.public')"
            />
          </div>
          <div class="col-12">
            <VSwatches v-model="form.color" :inline="true" />
          </div>
        </div>
      </form>
      <template #footer>
        <div class="float-sm-right">
          <Btn
            v-if="hangarGroup && hangarGroup.id"
            :disabled="deleting ? 'disabled' : null"
            :inline="true"
            @click.native="remove"
          >
            <i class="fal fa-trash" />
          </Btn>
          <Btn
            :form="`hangar-group-${id}`"
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
import Modal from '@/frontend/core/components/AppModal/Modal/index.vue'
import Btn from '@/frontend/core/components/Btn/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import { displayAlert, displayConfirm } from '@/frontend/lib/Noty'
import hangarGroupsCollection from '@/frontend/api/collections/HangarGroups'
import Checkbox from '@/frontend/core/components/Form/Checkbox/index.vue'
import VSwatches from 'vue-swatches'

export default {
  name: 'GroupModal',

  components: {
    Btn,
    Checkbox,
    FormInput,
    Modal,
    VSwatches,
  },

  props: {
    hangarGroup: {
      type: Object,
      default() {
        return {}
      },
    },
  },

  data() {
    return {
      deleting: false,
      form: null,
      submitting: false,
    }
  },

  computed: {
    id() {
      return (this.hangarGroup && this.hangarGroup.id) || 'new'
    },

    title() {
      if (this.hangarGroup && this.hangarGroup.id) {
        return this.$t('headlines.hangarGroup.edit')
      }

      return this.$t('headlines.hangarGroup.create')
    },
  },

  watch: {
    hangarGroup() {
      this.setupForm()
    },
  },

  mounted() {
    this.setupForm()
  },

  methods: {
    async create() {
      const response = await hangarGroupsCollection.create(this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('hangar-group-save')
        this.$comlink.$emit('close-modal')
      } else {
        displayAlert({
          text: response.error.response.data.message,
        })
      }
    },

    async destroy() {
      const success = await hangarGroupsCollection.destroy(this.hangarGroup.id)

      if (success) {
        this.$comlink.$emit('hangar-group-delete', this.hangarGroup)
        this.$comlink.$emit('close-modal')
      } else {
        this.deleting = false
      }
    },

    remove() {
      this.deleting = true

      displayConfirm({
        onClose: () => {
          this.deleting = false
        },
        onConfirm: () => {
          this.destroy()
        },
        text: this.$t('messages.confirm.hangarGroup.destroy'),
      })
    },

    async save() {
      this.submitting = true

      if (this.hangarGroup && this.hangarGroup.id) {
        this.update()
      } else {
        this.create()
      }
    },

    setupForm() {
      this.form = {
        color: this.hangarGroup?.color,
        name: this.hangarGroup?.name,
        public: this.hangarGroup?.public,
      }
    },

    async update() {
      const response = await hangarGroupsCollection.update(
        this.hangarGroup.id,
        this.form
      )

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('hangar-group-save')
        this.$comlink.$emit('close-modal')
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
