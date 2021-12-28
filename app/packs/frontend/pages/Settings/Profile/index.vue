<template>
  <ValidationObserver v-if="form" v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.settings.profile') }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="logo"
            :name="$t('labels.user.avatar')"
            :slim="true"
          >
            <div
              :class="{ 'has-error has-feedback': errors[0] }"
              class="form-group mb-3"
            >
              <VueUploadComponent
                ref="upload"
                :value="files"
                name="uploadAvatar"
                :extensions="fileExtensions"
                :accept="acceptedMimeTypes"
                class="avatar-uploader"
                @input="updatedValue"
                @input-filter="inputFilter"
              />
              <Avatar
                :avatar="avatarUrl"
                size="large"
                :editable="true"
                @upload="selectAvatar"
                @destroy="removeAvatar"
              />
            </div>
          </ValidationProvider>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
          <FormInput
            id="rsiHandle"
            v-model="form.rsiHandle"
            icon="icon icon-rsi icon-label"
            translation-key="user.rsiHandle"
          />
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-12 col-md-6">
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
        <div class="col-12 col-md-6">
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
              translation-key="discord"
              icon="fab fa-discord"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
      </div>
      <hr />
      <div class="row">
        <div class="col-12 col-md-6">
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
              translation-key="youtube"
              icon="fab fa-youtube"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
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
              translation-key="twitch"
              icon="fab fa-twitch"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>
        <div class="col-12 col-md-6">
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
              icon="fab fa-guilded"
              :clearable="true"
              translation-key="guilded"
              :error="errors[0]"
            />
          </ValidationProvider>
        </div>

        <div class="col-12">
          <br />
          <Btn :loading="submitting" type="submit" size="large">
            {{ $t('actions.save') }}
          </Btn>
        </div>
      </div>
    </form>
  </ValidationObserver>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter } from 'vuex-class'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'
import Btn from 'frontend/core/components/Btn'
import Avatar from 'frontend/core/components/Avatar'
import FormInput from 'frontend/core/components/Form/FormInput'
import VueUploadComponent from 'vue-upload-component'
import MetaInfo from 'frontend/mixins/MetaInfo'
import userCollection from 'frontend/api/collections/User'

@Component<SettingsAccount>({
  components: {
    VueUploadComponent,
    FormInput,
    Btn,
    Avatar,
  },
  mixins: [MetaInfo],
})
export default class SettingsAccount extends Vue {
  @Getter('currentUser', { namespace: 'session' }) currentUser

  form: UserForm | null = null

  files = []

  fileExtensions: string = 'jpg,jpeg,png,webp'

  acceptedMimeTypes: string = 'image/png,image/jpeg,image/webp'

  submitting: boolean = false

  get avatarUrl() {
    return this.newAvatar.url || (this.currentUser && this.currentUser.avatar)
  }

  get newAvatar() {
    return (this.files && this.files[0]) || {}
  }

  get fileExtensionsList() {
    return this.fileExtensions.split(',')
  }

  @Watch('currentUser')
  onCurrentUserChange() {
    this.setupForm()
  }

  created() {
    if (this.currentUser) {
      this.setupForm()
    }
  }

  selectAvatar() {
    this.form.removeAvatar = false
    this.$refs.upload.$el.querySelector('input').click()
  }

  removeAvatar() {
    this.files = []
    this.currentUser.avatar = null
    this.form.removeAvatar = true
  }

  setupForm() {
    this.form = {
      rsiHandle: this.currentUser.rsiHandle,
      homepage: this.currentUser.homepage,
      discord: this.currentUser.discord,
      youtube: this.currentUser.youtube,
      twitch: this.currentUser.twitch,
      guilded: this.currentUser.guilded,
      removeAvatar: false,
    }
  }

  async submit() {
    this.submitting = true

    const uploadResponse = await this.uploadAvatar()

    const response = await userCollection.updateProfile(this.form)

    this.submitting = false

    if (!uploadResponse.error && !response.error) {
      this.$comlink.$emit('user-update')

      setTimeout(() => {
        this.files = []
      }, 1000)

      displaySuccess({
        text: this.$t('messages.updateProfile.success'),
      })
    }
  }

  async uploadAvatar() {
    let uploadResponse = { error: null }

    if (this.newAvatar && this.newAvatar.file) {
      const uploadData = new FormData()
      uploadData.append('avatar', this.newAvatar.file)

      uploadResponse = await this.$api.upload('users/current', uploadData)
    }

    return uploadResponse
  }

  updatedValue(value) {
    this.files = value
  }

  inputFilter(newFile, oldFile, prevent) {
    if (newFile && !oldFile) {
      if (
        !this.fileExtensionsList.some((extension) =>
          newFile.name.endsWith(extension)
        )
      ) {
        displayAlert({
          text: this.$t('messages.avatarUpload.invalidExtension', {
            extensions: this.fileExtensions,
          }),
        })
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
}
</script>
