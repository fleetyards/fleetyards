<template>
  <section class="container">
    <form @submit.prevent="submit">
      <div class="row">
        <div class="col-md-12">
          <BreadCrumbs :crumbs="crumbs" />
          <h1>{{ $t('headlines.fleets.settings') }}</h1>
        </div>
      </div>

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
          <div
            :class="{'has-error has-feedback': errors.has('name')}"
            class="form-group"
          >
            <label for="name">
              {{ $t('labels.fleet.name') }}
            </label>
            <input
              id="name"
              v-model="form.name"
              v-tooltip.bottom-end="errors.first('name')"
              v-validate="'required|alpha_dash'"
              data-test="name"
              :data-vv-as="$t('labels.fleet.name')"
              :placeholder="$t('labels.fleet.name')"
              name="name"
              type="text"
              class="form-control"
            >
            <span
              v-show="errors.has('name')"
              class="form-control-feedback"
            >
              <i
                :title="errors.first('name')"
                class="fal fa-exclamation-triangle"
              />
            </span>
          </div>
        </div>
      </div>
      <br>
      <Btn
        :loading="submitting"
        type="submit"
        size="large"
      >
        {{ $t('actions.save') }}
      </Btn>
      <Btn
        :loading="deleting"
        size="large"
        variant="danger"
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
import Avatar from 'frontend/components/Avatar'

export default {
  name: 'FleetSettings',

  components: {
    VueUploadComponent,
    BreadCrumbs,
    Btn,
    Avatar,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        name: null,
        removeLogo: false,
      },
      fleet: null,
      loading: false,
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
  },

  watch: {
    $route() {
      this.fetch()
    },

    fleet: 'setupForm',
  },

  mounted() {
    this.fetch()

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
      this.form.name = this.fleet.name
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
        this.$comlink.$emit('fleetUpdate')

        setTimeout(() => {
          this.files = []
        }, 1000)

        this.fetch()

        this.$success({
          text: this.$t('messages.fleet.update.success'),
        })
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

    async fetch() {
      this.loading = true

      const response = await this.$api.get(`fleets/${this.$route.params.slug}`)

      this.loading = false

      if (!response.error) {
        this.fleet = response.data
      } else if (response.error.response && response.error.response.status === 404) {
        this.$router.replace({ name: '404' })
      }
    },
  },
}
</script>
