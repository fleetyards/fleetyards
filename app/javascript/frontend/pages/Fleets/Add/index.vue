<template>
  <section class="container">
    <form @submit.prevent="submit">
      <div class="row">
        <div class="col-xs-12 col-md-6 col-md-offset-3">
          <h1>{{ $t('headlines.fleets.add') }}</h1>
        </div>
      </div>

      <div class="row">
        <div class="col-xs-12 col-md-6 col-md-offset-3">
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
              v-validate="'required|alpha_dash|fleet'"
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
      <div class="row">
        <div class="col-xs-12 col-md-6 col-md-offset-3">
          <br>
          <Btn
            :loading="submitting"
            type="submit"
            size="large"
          >
            {{ $t('actions.save') }}
          </Btn>
        </div>
      </div>
    </form>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'

export default {
  name: 'FleetAdd',

  components: {
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        name: null,
      },
      loading: false,
      submitting: false,
    }
  },

  methods: {
    async submit() {
      const result = await this.$validator.validateAll()

      if (!result) {
        return
      }

      this.submitting = true

      const response = await this.$api.post('fleets', this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('fleetCreate')

        this.$success({
          text: this.$t('messages.fleet.create.success'),
        })
        this.$router.push({ name: 'fleet', params: { slug: response.data.slug } })
      } else {
        this.$alert({
          text: this.$t('messages.fleet.create.failure'),
        })
      }
    },
  },
}
</script>
