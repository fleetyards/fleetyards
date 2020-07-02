<template>
  <section class="container">
    <div class="row">
      <div class="col-lg-12">
        <BreadCrumbs :crumbs="crumbs" />
        <h1>{{ $t('headlines.fleets.settings.fleet') }}</h1>
      </div>
    </div>

    <ValidationObserver ref="form" v-slot="{ handleSubmit }" small>
      <form v-if="canEdit && fleet" @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="logo"
              :name="$t('labels.fleet.logo')"
              :slim="true"
            >
              <div
                :class="{ 'has-error has-feedback': errors[0] }"
                class="form-group mb-3"
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
                  :editable="true"
                  @upload="selectLogo"
                  @destroy="removeLogo"
                />
              </div>
            </ValidationProvider>
          </div>
        </div>
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="fid"
              :rules="{
                required: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_]{3,}$/,
              }"
              :name="$t('labels.fleet.fid')"
              :slim="true"
            >
              <FormInput
                id="fid"
                v-model="form.fid"
                translation-key="fleet.fid"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="name"
              :rules="{
                required: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_\. ]{3,}$/,
              }"
              :name="$t('labels.name')"
              :slim="true"
            >
              <FormInput
                id="name"
                v-model="form.name"
                translation-key="name"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <FormInput
              id="rsiSid"
              v-model="form.rsiSid"
              icon="icon icon-rsi icon-label"
              translation-key="fleet.rsiSid"
            />
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="homepage"
              rules="url"
              :name="$t('labels.homepage')"
              :slim="true"
            >
              <FormInput
                id="homepage"
                v-model="form.homepage"
                translation-key="homepage"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="discord"
              rules="url"
              :name="$t('labels.discord')"
              :slim="true"
            >
              <FormInput
                id="discord"
                v-model="form.discord"
                icon="fab fa-discord"
                translation-key="discord"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="ts"
              rules="url"
              :name="$t('labels.fleet.ts')"
              :slim="true"
            >
              <FormInput
                id="ts"
                v-model="form.ts"
                icon="fab fa-teamspeak"
                translation-key="fleet.ts"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
        </div>
        <hr />
        <div class="row">
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="youtube"
              rules="url"
              :name="$t('labels.youtube')"
              :slim="true"
            >
              <FormInput
                id="youtube"
                v-model="form.youtube"
                icon="fab fa-youtube"
                translation-key="youtube"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="twitch"
              rules="url"
              :name="$t('labels.twitch')"
              :slim="true"
            >
              <FormInput
                id="twitch"
                v-model="form.twitch"
                icon="fab fa-twitch"
                translation-key="twitch"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
          <div class="col-lg-12 col-xl-6">
            <ValidationProvider
              v-slot="{ errors }"
              vid="guilded"
              rules="url"
              :name="$t('labels.guilded')"
              :slim="true"
            >
              <FormInput
                id="guilded"
                v-model="form.guilded"
                icon="icon icon-guilded icon-label"
                translation-key="guilded"
                :error="errors[0]"
              />
            </ValidationProvider>
          </div>
        </div>
        <br />
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
    </ValidationObserver>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import VueUploadComponent from 'vue-upload-component'
import BreadCrumbs from 'frontend/core/components/BreadCrumbs'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import Avatar from 'frontend/core/components/Avatar'
import { displaySuccess, displayAlert, displayConfirm } from 'frontend/lib/Noty'
import { fleetRouteGuard } from 'frontend/utils/RouteGuards'
import fleetsCollection from 'frontend/api/collections/Fleets'

@Component<FleetSettings>({
  beforeRouteEnter: fleetRouteGuard,
  components: {
    VueUploadComponent,
    BreadCrumbs,
    Btn,
    FormInput,
    Avatar,
  },
  mixins: [MetaInfo],
})
export default class FleetSettings extends Vue {
  leaving: boolean = false

  submitting: boolean = false

  deleting: boolean = false

  files: any[] = []

  fileExtensions: string = 'jpg,jpeg,png,webp'

  acceptedMimeTypes: string = 'image/png,image/jpeg,image/webp'

  form: FleetForm = {
    fid: null,
    name: null,
    rsiSid: null,
    discord: null,
    ts: null,
    homepage: null,
    twitch: null,
    youtube: null,
    guilded: null,
    removeLogo: false,
  }

  get fleet() {
    return fleetsCollection.record
  }

  get metaTitle() {
    if (!this.fleet) {
      return null
    }

    return this.$t('title.fleets.settings', { fleet: this.fleet.name })
  }

  get logoUrl() {
    if (this.fleet) {
      return this.newLogo.url || this.fleet.logo
    }

    return this.newLogo.url
  }

  get newLogo() {
    return (this.files && this.files[0]) || {}
  }

  get crumbs() {
    if (!this.fleet) {
      return []
    }

    return [
      {
        to: {
          name: 'fleet',
          params: {
            slug: this.fleet.slug,
          },
        },
        label: this.fleet.name,
      },
    ]
  }

  get canEdit() {
    return this.fleet?.myRole === 'admin'
  }

  get leaveTooltip() {
    if (this.canEdit) {
      return this.$t('texts.fleets.leaveInfo')
    }

    return null
  }

  @Watch('$route')
  onRouteChange() {
    this.fetch()
  }

  @Watch('fleet')
  onFleetChange() {
    this.setupForm()
  }

  mounted() {
    this.fetch()

    if (this.fleet && !this.canEdit) {
      this.$router.replace({
        name: 'fleet-settings-membership',
        params: { slug: this.$route.params.slug },
      })
      return
    }

    if (this.fleet) {
      this.setupForm()
    }
  }

  selectLogo() {
    this.form.removeLogo = false
    this.$refs.upload.$el.querySelector('input').click()
  }

  removeLogo() {
    this.files = []
    this.fleet.logo = null
    this.form.removeLogo = true
  }

  setupForm() {
    this.form = {
      fid: this.fleet.fid,
      rsiSid: this.fleet.rsiSid,
      name: this.fleet.name,
      discord: this.fleet.discord,
      ts: this.fleet.ts,
      homepage: this.fleet.homepage,
      twitch: this.fleet.twitch,
      youtube: this.fleet.youtube,
      guilded: this.fleet.guilded,
      removeLogo: false,
    }
  }

  async submit() {
    this.submitting = true

    await this.uploadLogo()

    const response = await this.$api.put(
      `fleets/${this.$route.params.slug}`,
      this.form,
    )

    this.submitting = false

    if (!response.error) {
      displaySuccess({
        text: this.$t('messages.fleet.update.success'),
      })

      this.$comlink.$emit('fleetUpdate')

      if (response.data.slug !== this.$route.params.slug) {
        await this.$router.replace({
          name: 'fleet-settings',
          params: { slug: response.data.slug },
        })
      }
    } else {
      this.handlerUpdateError(response.error)
    }
  }

  async uploadLogo() {
    if (!this.newLogo || !this.newLogo.file) {
      return
    }

    const uploadData = new FormData()
    uploadData.append('logo', this.newLogo.file)

    const response = await this.$api.upload(
      `fleets/${this.$route.params.slug}`,
      uploadData,
    )

    if (!response.error) {
      displaySuccess({
        text: this.$t('messages.fleet.update.logo.success'),
      })

      this.$comlink.$emit('fleetUpdate')

      setTimeout(() => {
        this.files = []
      }, 1000)
    } else {
      this.handleUpdateError(response.error)
    }
  }

  handleUpdateError(error) {
    if (error.response && error.response.data) {
      const { data: errorData } = error.response

      this.$refs.form.setErrors(errorData.errors)

      displayAlert({
        text: errorData.message,
      })
    } else {
      displayAlert({
        text: this.$t('messages.fleet.update.failure'),
      })
    }
  }

  async destroy() {
    this.deleting = true
    displayConfirm({
      text: this.$t('messages.confirm.fleet.destroy'),
      onConfirm: async () => {
        const response = await this.$api.destroy(
          `fleets/${this.$route.params.slug}`,
        )

        if (!response.error) {
          this.$router.push({ name: 'home' })

          this.$comlink.$emit('fleetUpdate')

          displaySuccess({
            text: this.$t('messages.fleet.destroy.success'),
          })
        } else {
          displayAlert({
            text: this.$t('messages.fleet.destroy.failure'),
          })
          this.deleting = false
        }
      },
      onClose: () => {
        this.deleting = false
      },
    })
  }

  updatedValue(value) {
    this.files = value
  }

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
  }

  async fetch() {
    await fleetsCollection.findBySlug(this.$route.params.slug)
  }
}
</script>
