<template>
  <section class="container">
    <ValidationObserver v-slot="{ handleSubmit }" small>
      <form @submit.prevent="handleSubmit(submit)">
        <div class="row justify-content-lg-center">
          <div class="col-12 col-lg-6">
            <h1>{{ $t('headlines.fleets.add') }}</h1>
          </div>
        </div>

        <div class="row justify-content-lg-center">
          <div class="col-12 col-lg-6">
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
        <div class="row justify-content-lg-center">
          <div class="col-12 col-lg-6">
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
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'
import fleetsCollection from 'frontend/api/collections/Fleets'

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

      const fleet = await fleetsCollection.create(this.form)

      this.submitting = false

      if (fleet) {
        this.$comlink.$emit('fleetCreate')

        displaySuccess({
          text: this.$t('messages.fleet.create.success'),
        })

        this.$router.push({
          name: 'fleet',
          params: { slug: fleet.slug },
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
