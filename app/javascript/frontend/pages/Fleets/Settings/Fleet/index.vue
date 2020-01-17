<template>
  <section class="container">
    <div class="row">
      <div class="col-md-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.fleet') }}</h1>
      </div>
    </div>

    <form
      v-if="canEdit && fleet"
      @submit.prevent="submit"
    >
      <div class="row">
        <div class="col-md-12 col-lg-6">
          <div
            :class="{'has-error has-feedback': errors.has('logo')}"
            class="form-group"
          >
            <VueUploadComponent
              ref="upload"
              :value="files"
              name="uploadLogo"
              :extensions="fileExtensions"
              :accept="acceptedMimeTypes"
              class="avatar-uploader"
              @input="updatedValue"
              @input-filter="inputFilter"
            />
            <Avatar
              :avatar="logoUrl"
              size="large"
              icon="fad fa-image"
              editable
              @upload="selectLogo"
              @destroy="removeLogo"
            />
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12 col-lg-6">
          <FormInput
            v-model="form.fid"
            v-validate="{
              required: true,
              min: 3,
              regex: /^[a-zA-Z0-9\-_]{3,}$/
            }"
            :data-vv-as="$t('labels.fleet.fid')"
            :placeholder="$t('labels.fleet.fid')"
            :label="$t('labels.fleet.fid')"
            :error="errors.first('fid')"
            name="fid"
          />
        </div>
        <div class="col-md-12 col-lg-6">
          <FormInput
            v-model="form.name"
            v-validate="{
              required: true,
              min: 3,
              regex: /^[a-zA-Z0-9\-_\. ]{3,}$/
            }"
            :data-vv-as="$t('labels.fleet.name')"
            :placeholder="$t('labels.fleet.name')"
            :label="$t('labels.fleet.name')"
            :error="errors.first('name')"
            name="name"
          />
        </div>
      </div>
      <br>
      <Btn
        :loading="submitting"
        type="submit"
        size="large"
        data-test="fleet-save"
      >
        {{ $t('actions.save') }}
      </Btn>
      <Btn
        :loading="deleting"
        size="large"
        variant="danger"
        data-test="fleet-delete"
        @click.native="destroy"
      >
        {{ $t('actions.delete') }}
      </Btn>
    </form>
  </section>
</template>

<script>
import VueUploadComponent from 'vue-upload-component'
import BreadCrumbs from 'frontend/components/BreadCrumbs'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import Avatar from 'frontend/components/Avatar'
import FleetsMixin from 'frontend/mixins/Fleets'

export default {
  name: 'FleetSettings',

  components: {
    VueUploadComponent,
    BreadCrumbs,
    Btn,
    FormInput,
    Avatar,
  },

  mixins: [
    MetaInfo,
    FleetsMixin,
  ],

  props: {
    fleet: {
      type: Object,
      required: true,
    },
  },

  data() {
    return {
      form: {
        fid: null,
        name: null,
        removeLogo: false,
      },
      loading: false,
      leaving: false,
      submitting: false,
      deleting: false,
      files: [],
      fileExtensions: 'jpg,jpeg,png,webp',
      acceptedMimeTypes: 'image/png,image/jpeg,image/webp',
    }
  },

  computed: {
    metaTitle() {
      if (!this.fleet) {
        return null
      }

      return this.$t('title.fleets.settings', { fleet: this.fleet.name })
    },


    logoUrl() {
      if (this.fleet) {
        return this.newLogo.url || this.fleet.logo
      }

      return this.newLogo.url
    },

    newLogo() {
      return ((this.files && this.files[0]) || {})
    },

    crumbs() {
      if (!this.fleet) {
        return []
      }

      return [{
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      }]
    },

    canEdit() {
      return this.myFleetRole === 'admin'
    },

    leaveTooltip() {
      if (this.myFleet && this.myFleet.role === 'admin') {
        return this.$t('texts.fleets.leaveInfo')
      }

      return null
    },
  },

  watch: {
    fleet: 'setupForm',
  },

  mounted() {
    if (this.fleet) {
      this.setupForm()
    }
  },

  methods: {
    selectLogo() {
      this.form.removeLogo = false
      this.$refs.upload.$el.querySelector('input').click()
    },

    removeLogo() {
      this.files = []
      this.fleet.logo = null
      this.form.removeLogo = true
    },

    setupForm() {
      this.form = {
        fid: this.fleet.fid,
        sid: this.fleet.sid,
        public: this.fleet.public,
        name: this.fleet.name,
      }
    },

    async submit() {
      const result = await this.$validator.validateAll()

      if (!result) {
        return
      }

      this.submitting = true

      const data = new FormData()
      if (this.newLogo && this.newLogo.file) {
        data.append('logo', this.newLogo.file)
      }
      if (this.form.removeLogo) {
        data.append('removeLogo', true)
      }
      data.append('name', this.form.name)

      const response = await this.$api.upload(`fleets/${this.$route.params.slug}`, data)

      this.submitting = false

      if (!response.error) {
        this.$success({
          text: this.$t('messages.fleet.update.success'),
        })

        this.$comlink.$emit('fleetUpdate')

        if (response.data.slug !== this.$route.params.slug) {
          this.$router.push({ name: 'fleet-settings', params: { slug: response.data.slug } })
        } else {
          setTimeout(() => {
            this.files = []
          }, 1000)

          this.fetch()
        }
      } else {
        const { error } = response
        if (error.response && error.response.data) {
          const { data: errorData } = error.response

          errorData.errors.map((item) => ({
            field: item[0],
            errors: item[1],
          })).forEach((item) => {
            item.errors.forEach((errorItem) => this.errors.add({
              field: item.field,
              msg: errorItem,
            }))
          })

          this.$alert({
            text: errorData.message,
          })
        } else {
          this.$alert({
            text: this.$t('messages.fleet.update.failure'),
          })
        }
      }
    },

    async destroy() {
      this.deleting = true
      this.$confirm({
        text: this.$t('messages.confirm.fleet.destroy'),
        onConfirm: async () => {
          const response = await this.$api.destroy(`fleets/${this.$route.params.slug}`)

          if (!response.error) {
            this.$comlink.$emit('fleetUpdate')

            this.$success({
              text: this.$t('messages.fleet.destroy.success'),
            })

            this.$router.push({ name: 'home' })
          } else {
            this.$alert({
              text: this.$t('messages.fleet.destroy.failure'),
            })
            this.deleting = false
          }
        },
        onClose: () => {
          this.deleting = false
        },
      })
    },

    updatedValue(value) {
      this.files = value
    },

    inputFilter(newFile, oldFile, prevent) {
      if (newFile && !oldFile) {
        if (!/\.(gif|jpg|jpeg|png|webp)$/i.test(newFile.name)) {
          this.alert('Your choice is not a picture')
          return prevent()
        }
      }
      if (newFile && (!oldFile || newFile.file !== oldFile.file)) {
        // eslint-disable-next-line no-param-reassign
        newFile.url = ''
        const URL = window.URL || window.webkitURL
        if (URL && URL.createObjectURL) {
          // eslint-disable-next-line no-param-reassign
          newFile.url = URL.createObjectURL(newFile.file)
        }
      }

      return null
    },
  },
}
</script>
