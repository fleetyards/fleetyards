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
              <form @submit.prevent="handleSubmit(submit)">
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

<script>
import { mapGetters, mapActions } from 'vuex'
import Btn from '@/frontend/core/components/Btn/index.vue'
import FormInput from '@/frontend/core/components/Form/FormInput/index.vue'
import { displayAlert } from '@/frontend/lib/Noty'
import sessionCollection from '@/frontend/api/collections/Session'

export default {
  name: 'SecurePageForm',

  components: {
    Btn,
    FormInput,
  },

  data() {
    return {
      confirmed: false,
      password: null,
      submitting: false,
    }
  },

  computed: {
    ...mapGetters('session', ['accessConfirmed']),

    metaTitle() {
      return this.$t(`title.confirmAccess`)
    },
  },

  watch: {
    confirmed() {
      if (this.confirmed) {
        this.$comlink.$emit('access-confirmed')
      }
    },
  },

  mounted() {
    this.$comlink.$on('access-confirmation-required', this.resetConfirmation)
  },

  beforeDestroy() {
    this.$comlink.$off('access-confirmation-required')
  },

  created() {
    if (this.accessConfirmed) {
      this.confirmed = true
    }
  },

  methods: {
    ...mapActions('session', ['confirmAccess', 'resetConfirmAccess']),

    resetConfirmation() {
      this.confirmed = false
      this.resetConfirmAccess()
    },

    async submit() {
      this.submitting = true

      const response = await sessionCollection.confirmAccess(this.password)

      this.password = null

      this.submitting = false

      if (response) {
        this.confirmed = true
        this.confirmAccess()
      } else {
        displayAlert({
          text: this.$t('messages.confirmAccess.failure'),
        })
      }
    },
  },
}
</script>

<style lang="scss" scoped>
@import '@/stylesheets/variables';

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
