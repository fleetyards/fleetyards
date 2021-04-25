<template>
  <div>
    <transition name="fade" mode="out-in" appear>
      <slot v-if="confirmed" />
      <section
        v-else
        class="container confirm-access"
        data-test="confirm-access"
      >
        <div class="row">
          <div class="col-12">
            <ValidationObserver
              ref="form"
              v-slot="{ handleSubmit }"
              :small="true"
            >
              <form @submit.prevent="handleSubmit(confirmAccess)">
                <h1>{{ $t('headlines.confirmAccess') }}</h1>

                <ValidationProvider
                  v-slot="{ errors }"
                  vid="password"
                  rules="required"
                  :name="$t('labels.password')"
                  :slim="true"
                >
                  <FormInput
                    id="password"
                    v-model="password"
                    :error="errors[0]"
                    type="password"
                    :autofocus="true"
                  />
                </ValidationProvider>

                <Btn
                  :loading="submitting"
                  type="submit"
                  :class="{ confirmed: confirmed }"
                  data-test="submit-confirm-access"
                  :block="true"
                >
                  {{ $t('actions.confirmAccess') }}
                </Btn>
              </form>
            </ValidationObserver>
          </div>
        </div>
      </section>
    </transition>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Watch } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import Btn from 'frontend/core/components/Btn'
import FormInput from 'frontend/core/components/Form/FormInput'
import { displayAlert } from 'frontend/lib/Noty'
import sessionCollection from 'frontend/api/collections/Session'

@Component<Signup>({
  components: {
    Btn,
    FormInput,
  },
})
export default class Signup extends Vue {
  @Getter('accessConfirmed', { namespace: 'session' }) accessConfirmed: boolean

  @Action('confirmAccess', { namespace: 'session' }) saveConfirmAccess: any

  @Action('resetConfirmAccess', { namespace: 'session' })
  resetConfirmAccess: any

  submitting: boolean = false

  password: string = null

  confirmed: boolean = false

  get metaTitle() {
    return this.$t(`title.confirmAccess`)
  }

  mounted() {
    this.$comlink.$on('access-confirmation-required', this.resetConfirmation)
  }

  created() {
    if (this.accessConfirmed) {
      this.confirmed = true
    }
  }

  beforeDestroy() {
    this.$comlink.$off('access-confirmation-required')
  }

  @Watch('confirmed')
  onConfirmedChange() {
    if (this.confirmed) {
      this.$comlink.$emit('access-confirmed')
    }
  }

  resetConfirmation() {
    this.confirmed = false
    this.resetConfirmAccess()
  }

  async confirmAccess() {
    this.submitting = true

    const response = await sessionCollection.confirmAccess(this.password)

    this.password = null

    this.submitting = false

    if (response) {
      this.confirmed = true
      this.saveConfirmAccess()
    } else {
      displayAlert({
        text: this.$t('messages.confirmAccess.failure'),
      })
    }
  }
}
</script>

<style lang="scss" scoped>
@import '~stylesheets/variables';

form {
  max-width: 300px;
  margin: 0 auto;
}

button[type='submit'] {
  transition: color $transition-base-speed ease;

  .confirmed {
    color: green;
  }
}
</style>
