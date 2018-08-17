<template>
  <div/>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import { success, alert } from 'frontend/lib/Noty'

export default {
  mixins: [I18n],
  created() {
    this.fetch()
  },
  methods: {
    async fetch() {
      const response = await this.$api.post('users/confirm', { token: this.$route.params.token })
      if (!response.error) {
        success(this.t('messages.confirm.success'))
      } else {
        alert(this.t('messages.confirm.failure'))
      }
      this.$router.push('/')
    },
  },
}
</script>
