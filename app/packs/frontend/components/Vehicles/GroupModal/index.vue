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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop, Watch } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import { displayAlert, displayConfirm } from 'frontend/lib/Noty'
import hangarGroupsCollection from 'frontend/api/collections/HangarGroups'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import VSwatches from 'vue-swatches'

@Component<GroupModal>({
  components: {
    Modal,
    Btn,
    FormInput,
    VSwatches,
    Checkbox,
  },
})
export default class GroupModal extends Vue {
  @Prop({
    default() {
      return {}
    },
  })
  hangarGroup: HangarGroup

  submitting: boolean = false

  deleting: boolean = false

  form: HangarGroupForm | null = null

  get title() {
    if (this.hangarGroup && this.hangarGroup.id) {
      return this.$t('headlines.hangarGroup.edit')
    }

    return this.$t('headlines.hangarGroup.create')
  }

  get id() {
    return (this.hangarGroup && this.hangarGroup.id) || 'new'
  }

  mounted() {
    this.setupForm()
  }

  @Watch('hangarGroup')
  onHangarGroupChange() {
    this.setupForm()
  }

  setupForm() {
    this.form = {
      name: this.hangarGroup?.name,
      color: this.hangarGroup?.color,
      public: this.hangarGroup?.public,
    }
  }

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
  }

  async destroy() {
    const success = await hangarGroupsCollection.destroy(this.hangarGroup.id)

    if (success) {
      this.$comlink.$emit('hangar-group-delete', this.hangarGroup)
      this.$comlink.$emit('close-modal')
    } else {
      this.deleting = false
    }
  }

  async save() {
    this.submitting = true

    if (this.hangarGroup && this.hangarGroup.id) {
      this.update()
    } else {
      this.create()
    }
  }

  async update() {
    const success = await hangarGroupsCollection.update(
      this.hangarGroup.id,
      this.form
    )

    this.submitting = false

    if (success) {
      this.$comlink.$emit('hangar-group-save')
      this.$comlink.$emit('close-modal')
    } else {
      displayAlert({
        text: response.error.response.data.message,
      })
    }
  }

  async create() {
    const newHangarGroup = await hangarGroupsCollection.create(this.form)

    this.submitting = false

    if (newHangarGroup) {
      this.$comlink.$emit('hangar-group-save')
      this.$comlink.$emit('close-modal')
    } else {
      displayAlert({
        text: response.error.response.data.message,
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
