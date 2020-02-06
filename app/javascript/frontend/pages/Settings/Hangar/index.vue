<template>
  <form @submit.prevent="submit">
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.settings.hangar') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12 col-lg-6">
        <Checkbox
          id="saleNotify"
          v-model="form.saleNotify"
          :label="$t('labels.user.saleNotify')"
        />
        <Checkbox
          id="publicHangar"
          v-model="form.publicHangar"
          :label="$t('labels.user.publicHangar')"
        />
      </div>
    </div>
    <br />
    <Btn :loading="submitting" type="submit" size="large">
      {{ $t('actions.save') }}
    </Btn>
  </form>
</template>

<script>
import { mapGetters } from 'vuex'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import Checkbox from 'frontend/components/Form/Checkbox'

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
    if (this.currentUser) {
      this.setupForm()
    }
  },

  methods: {
    setupForm() {
      this.form.saleNotify = !!this.currentUser.saleNotify
      this.form.publicHangar = !!this.currentUser.publicHangar
    },

    async submit() {
      const result = await this.$validator.validateAll()
      if (!result) {
        return
      }
      this.submitting = true
      const response = await this.$api.put('users/current', this.form)
      this.submitting = false
      if (!response.error) {
        this.$comlink.$emit('userUpdate')
        this.$success({
          text: this.$t('messages.updateProfile.success'),
        })
      }
    },
  },
}
</script>
