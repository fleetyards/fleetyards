<template>
  <div />
</template>

<script>
import { displaySuccess, displayAlert } from 'frontend/lib/Noty'

export default {
  name: 'ConfirmAccount',

  created() {
    this.fetch()
  },

  methods: {
    async fetch() {
      const response = await this.$api.post('users/confirm', {
        token: this.$route.params.token,
      })

      if (!response.error) {
        this.$comlink.$emit('user-update')

        displaySuccess({
          text: this.$t('messages.accountConfirm.success'),
        })

        await this.$store.dispatch('hangar/enableStarterGuide')
      } else {
        displayAlert({
          text: this.$t('messages.accountConfirm.failure'),
        })
      }

      // eslint-disable-next-line @typescript-eslint/no-empty-function
      this.$router.push('/').catch(() => {})
    },
  },
}
</script>
