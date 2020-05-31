<template>
  <div />
</template>

<script>
export default {
  created() {
    this.fetch()
  },

  methods: {
    async fetch() {
      const response = await this.$api.post('users/confirm', {
        token: this.$route.params.token,
      })

      if (!response.error) {
        this.$success({
          text: this.$t('messages.accountConfirm.success'),
        })

        await this.$store.dispatch('hangar/enableStarterGuide')
      } else {
        this.$alert({
          text: this.$t('messages.accountConfirm.failure'),
        })
      }

      this.$router.push('/')
    },
  },
}
</script>
