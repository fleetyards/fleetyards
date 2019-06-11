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
      const response = await this.$api.post('users/confirm', { token: this.$route.params.token })
      if (!response.error) {
        this.$success(this.$t('messages.confirm.success'))
      } else {
        this.$alert(this.$t('messages.confirm.failure'))
      }
      this.$router.push('/')
    },
  },
}
</script>
