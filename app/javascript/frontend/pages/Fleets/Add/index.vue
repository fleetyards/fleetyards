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
          <FormInput
            v-model="form.fid"
            v-validate="{
              required: true,
              fleet: true,
              min: 3,
              regex: /^[a-zA-Z0-9\-_]{3,}$/
            }"
            :data-vv-as="$t('labels.fleet.fid')"
            :placeholder="$t('labels.fleet.fid')"
            :label="$t('labels.fleet.fid')"
            :error="errors.first('fid')"
            name="fid"
            size="large"
          />

          <FormInput
            v-model="form.name"
            v-validate="{
              required: true,
              fleet: true,
              min: 3,
              regex: /^[a-zA-Z0-9\-_\. ]{3,}$/
            }"
            :data-vv-as="$t('labels.fleet.name')"
            :placeholder="$t('labels.fleet.name')"
            :label="$t('labels.fleet.name')"
            :error="errors.first('name')"
            name="name"
            size="large"
          />
        </div>
      </div>
      <div class="row">
        <div class="col-xs-12 col-md-6 col-md-offset-3">
          <br>
          <Btn
            :loading="submitting"
            type="submit"
            size="large"
            data-test="fleet-save"
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
import FormInput from 'frontend/components/Form/FormInput'

export default {
  name: 'FleetAdd',

  components: {
    Btn,
    FormInput,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      form: {
        fid: null,
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
