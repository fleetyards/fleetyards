<template>
  <section>
    <div class="row">
      <div class="col-md-12">
        <h1>{{ $t('headlines.account') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12">
        <p>
          {{ $t('labels.account.destroyInfo') }}
        </p>
        <Btn
          :loading="deleting"
          variant="danger"
          size="large"
          @click.native="destroy"
        >
          {{ $t('actions.destroyAccount') }}
        </Btn>
      </div>
    </div>
  </section>
</template>

<script>
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'

export default {
  name: 'SettingsAccount',

  components: {
    Btn,
  },

  mixins: [
    MetaInfo,
  ],

  data() {
    return {
      deleting: false,
    }
  },

  methods: {
    async destroy() {
      this.deleting = true
      this.$confirm({
        text: this.$t('messages.confirm.account.destroy'),
        onConfirm: async () => {
          const response = await this.$api.destroy('users/current')
          if (!response.error) {
            this.$success({
              text: this.$t('messages.account.destroy.success'),
            })
            await this.$store.dispatch('session/logout')
            this.$router.push({ name: 'home' })
          } else {
            this.$alert({
              text: this.$t('messages.account.destroy.error'),
            })
            this.deleting = false
          }
        },
        onClose: () => {
          this.deleting = false
        },
      })
    },
  },
}
</script>
