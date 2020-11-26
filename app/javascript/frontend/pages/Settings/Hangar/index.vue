<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.settings.hangar') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-lg-12 col-xl-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="saleNotify"
            :name="$t('labels.user.saleNotify')"
            :slim="true"
          >
            <Checkbox
              id="saleNotify"
              v-model="form.saleNotify"
              :label="$t('labels.user.saleNotify')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>

          <ValidationProvider
            v-slot="{ errors }"
            vid="publicHangar"
            :name="$t('labels.user.publicHangar')"
            :slim="true"
          >
            <Checkbox
              id="publicHangar"
              v-model="form.publicHangar"
              :label="$t('labels.user.publicHangar')"
              :class="{ 'has-error has-feedback': errors[0] }"
            />
          </ValidationProvider>
        </div>
      </div>
      <br />
      <Btn :loading="submitting" type="submit" size="large">
        {{ $t('actions.save') }}
      </Btn>
    </form>
  </ValidationObserver>
</template>

<script>
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/core/components/Btn'
import Checkbox from 'frontend/core/components/Form/Checkbox'
import { displaySuccess } from 'frontend/lib/Noty'

export default {
  name: 'Profile',

  components: {
    Btn,
    Checkbox,
  },

  mixins: [MetaInfo],

  data() {
    return {
      form: {
        saleNotify: false,
        publicHangar: true,
      },
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  watch: {
    currentUser: 'setupForm',
  },

  created() {
    this.setupForm()
  },

  methods: {
    setupForm() {
      if (!this.currentUser) {
        return
      }

      this.form.saleNotify = !!this.currentUser.saleNotify
      this.form.publicHangar = !!this.currentUser.publicHangar
    },

    async submit() {
      this.submitting = true

      const response = await this.$api.put('users/current', this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('user-update')

        displaySuccess({
          text: this.$t('messages.updateProfile.success'),
        })
      }
    },
  },
}
</script>
