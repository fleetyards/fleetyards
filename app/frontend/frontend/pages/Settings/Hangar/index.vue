<template>
  <ValidationObserver v-if="form" v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.settings.hangar') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
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
        <div class="col-12 col-md-6">
          <ValidationProvider
            v-slot="{ errors }"
            vid="publicHangarLoaners"
            :name="$t('labels.user.publicHangarLoaners')"
            :slim="true"
          >
            <Checkbox
              id="publicHangarLoaners"
              v-model="form.publicHangarLoaners"
              :label="$t('labels.user.publicHangarLoaners')"
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
import { displaySuccess } from '@/frontend/lib/Noty'
import Btn from '@/frontend/core/components/Btn'
import Checkbox from '@/frontend/core/components/Form/Checkbox'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import userCollection from '@/frontend/api/collections/User'

export default {
  name: 'SettingsHangar',

  components: {
    Btn,
    Checkbox,
  },

  mixins: [MetaInfo],

  data() {
    return {
      form: null,
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', ['currentUser']),
  },

  watch: {
    currentUser() {
      this.setupForm()
    },
  },

  created() {
    if (this.currentUser) {
      this.setupForm()
    }
  },

  methods: {
    setupForm() {
      this.form = {
        publicHangar: this.currentUser.publicHangar,
        publicHangarLoaners: this.currentUser.publicHangarLoaners,
      }
    },

    async submit() {
      this.submitting = true

      const response = await userCollection.updateProfile(this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('user-update')

        displaySuccess({
          text: this.$t('messages.updateHangar.success'),
        })
      }
    },
  },
}
</script>
