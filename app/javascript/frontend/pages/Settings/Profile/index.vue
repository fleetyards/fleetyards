<template>
  <ValidationObserver
    v-slot="{ handleSubmit }"
    slim
  >
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-md-12">
          <h1>{{ $t('headlines.settings.profile') }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-md-12 col-lg-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="logo"
            :name="$t('labels.user.avatar')"
            slim
          >
            <div
              :class="{'has-error has-feedback': errors[0]}"
              class="form-group"
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
                editable
                @upload="selectAvatar"
                @destroy="removeAvatar"
              />
            </div>
          </ValidationProvider>
        </div>
      </div>
      <div class="row">
        <div class="col-md-12 col-lg-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="username"
            rules="required|alpha_dash"
            :name="$t('labels.username')"
            slim
          >
            <FormInput
              id="username"
              v-model="form.username"
              :error="errors[0]"
            />
          </ValidationProvider>
          <ValidationProvider
            v-slot="{ errors }"
            vid="email"
            rules="required|email"
            :name="$t('labels.email')"
            slim
          >
            <FormInput
              id="email"
              v-model="form.email"
              :error="errors[0]"
              type="email"
            />
          </ValidationProvider>
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
    </form>
  </ValidationObserver>
</template>

<script>
import { mapGetters } from 'vuex'
import VueUploadComponent from 'vue-upload-component'
import MetaInfo from 'frontend/mixins/MetaInfo'
import FormInput from 'frontend/components/Form/FormInput'
import Btn from 'frontend/components/Btn'
import Avatar from 'frontend/components/Avatar'

export default {
  name: 'Profile',

  components: {
    VueUploadComponent,
    FormInput,
    Btn,
    Avatar,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        username: null,
        email: null,
        removeAvatar: false,
      },
      files: [],
      fileExtensions: 'jpg,jpeg,png,webp',
      acceptedMimeTypes: 'image/png,image/jpeg,image/webp',
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', [
      'currentUser',
    ]),

    avatarUrl() {
      return this.newAvatar.url || this.currentUser.avatar
    },

    newAvatar() {
      return ((this.files && this.files[0]) || {})
    },
  },

  watch: {
    currentUser: 'setupForm',
  },

  created() {
    if (this.currentUser) {
      this.setupForm()
    }
  },

  methods: {
    selectAvatar() {
      this.form.removeAvatar = false
      this.$refs.upload.$el.querySelector('input').click()
    },

    removeAvatar() {
      this.files = []
      this.currentUser.avatar = null
      this.form.removeAvatar = true
    },

    setupForm() {
      this.form.username = this.currentUser.username
      this.form.email = this.currentUser.email
    },

    async submit() {
      this.submitting = true

      const data = new FormData()
      if (this.newAvatar && this.newAvatar.file) {
        data.append('avatar', this.newAvatar.file)
      }
      if (this.form.removeAvatar) {
        data.append('removeAvatar', true)
      }
      data.append('username', this.form.username)
      data.append('email', this.form.email)

      const response = await this.$api.upload('users/current', data)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('userUpdate')

        setTimeout(() => {
          this.files = []
        }, 1000)

        this.$success({
          text: this.$t('messages.updateProfile.success'),
        })
      }
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
