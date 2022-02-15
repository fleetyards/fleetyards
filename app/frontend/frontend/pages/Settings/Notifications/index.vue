<template>
  <ValidationObserver v-slot="{ handleSubmit }" :slim="true">
    <form @submit.prevent="handleSubmit(submit)">
      <div class="row">
        <div class="col-lg-12">
          <h1>{{ $t('headlines.settings.notifications') }}</h1>
        </div>
      </div>
      <div class="row">
        <div class="col-12 col-md-6">
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
import Btn from '@/frontend/core/components/Btn/index.vue'
import Checkbox from '@/frontend/core/components/Form/Checkbox/index.vue'
import MetaInfo from '@/frontend/mixins/MetaInfo'
import userCollection from '@/frontend/api/collections/User'
import { displaySuccess } from '@/frontend/lib/Noty'

export default {
  name: 'SettingsNotifications',

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
        saleNotify: this.currentUser.saleNotify,
      }
    },

    async submit() {
      this.submitting = true

      const response = await userCollection.updateAccount(this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('user-update')

        displaySuccess({
          text: this.$t('messages.updateNotifications.success'),
        })
      }
    },
  },
}
</script>
