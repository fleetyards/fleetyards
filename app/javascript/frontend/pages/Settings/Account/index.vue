<template>
  <section>
    <div class="row">
      <div class="col-md-12">
        <h1>{{ t('headlines.account') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-md-12">
        <p>
          {{ t('labels.account.destroyInfo') }}
        </p>
        <Btn
          :loading="deleting"
          danger
          large
          @click.native="destroy"
        >
          {{ t('actions.destroyAccount') }}
        </Btn>
      </div>
    </div>
  </section>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Btn from 'frontend/components/Btn'
import { success, confirm, alert } from 'frontend/lib/Noty'

export default {
  components: {
    Btn,
  },
  mixins: [I18n, MetaInfo],
  data() {
    return {
      deleting: false,
    }
  },
  methods: {
    destroy() {
      this.deleting = true
      confirm(this.t('confirm.account.destroy'), () => {
        this.$api.destroy('users/current', (args) => {
          if (!args.error) {
            success(this.t('messages.account.destroy.success'))
            this.$store.commit('logout')
            this.$router.push({ name: 'home' })
          } else {
            alert(this.t('messages.account.destroy.error'))
            this.deleting = false
          }
        })
      }, () => {
        this.deleting = false
      })
    },
  },
  metaInfo() {
    return this.getMetaInfo({
      title: this.t('title.account')
    })
  },
}
</script>
