<template>
  <section class="container">
    <ValidationObserver v-slot="{ handleSubmit }" small>
      <form @submit.prevent="handleSubmit(submit)">
        <div class="row">
          <div class="col-xs-12 col-md-6 col-md-offset-3">
            <h1>{{ $t('headlines.fleets.add') }}</h1>
          </div>
        </div>

        <div class="row">
          <div class="col-xs-12 col-md-6 col-md-offset-3">
            <ValidationProvider
              v-slot="{ errors }"
              vid="fid"
              :rules="{
                required: true,
                fidTaken: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_]{3,}$/,
              }"
              :name="$t('labels.fleet.fid')"
              slim
            >
              <FormInput
                id="fid"
                v-model="form.fid"
                translation-key="fleet.fid"
                :error="errors[0]"
                size="large"
              />
            </ValidationProvider>
            <ValidationProvider
              v-slot="{ errors }"
              vid="name"
              :rules="{
                required: true,
                min: 3,
                regex: /^[a-zA-Z0-9\-_\. ]{3,}$/,
              }"
              :name="$t('labels.name')"
              slim
            >
              <FormInput
                id="name"
                v-model="form.name"
                translation-key="name"
                :error="errors[0]"
                size="large"
              />
            </ValidationProvider>
          </div>
        </div>
        <div class="row">
          <div class="col-xs-12 col-md-6 col-md-offset-3">
            <br />
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
    </ValidationObserver>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import FormInput from 'frontend/components/Form/FormInput'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  name: 'FleetAdd',

  components: {
    Btn,
    FormInput,
  },

  mixins: [MetaInfo],

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
      this.submitting = true

      const response = await this.$api.post('fleets', this.form)

      this.submitting = false

      if (!response.error) {
        this.$comlink.$emit('fleetCreate')

        displaySuccess({
          text: this.$t('messages.fleet.create.success'),
        })

        this.$router.push({
          name: 'fleet',
          params: { slug: response.data.slug },
        })
      } else {
        displayAlert({
          text: this.$t('messages.fleet.create.failure'),
        })
      }
    },
  },
}
</script>
