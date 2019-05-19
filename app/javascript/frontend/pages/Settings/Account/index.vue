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
import { success, confirm, alert } from 'frontend/lib/Noty'

export default {
  components: {
    Btn,
  },
  mixins: [MetaInfo],
  data() {
    return {
      deleting: false,
    }
  },
  methods: {
    async destroy() {
      this.deleting = true
      confirm(this.$t('confirm.account.destroy'), async () => {
        const response = await this.$api.destroy('users/current')
        if (!response.error) {
          success(this.$t('messages.account.destroy.success'))
          await this.$store.dispatch('session/logout')
          this.$router.push({ name: 'home' })
        } else {
          alert(this.$t('messages.account.destroy.error'))
          this.deleting = false
        }
      }, () => {
        this.deleting = false
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.$t('title.account'),
    })
  },
}
</script>
