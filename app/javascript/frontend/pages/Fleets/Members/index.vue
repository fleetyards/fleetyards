<template>
  <div class="col-xs-12">
    foo
  </div>
</template>

<script>
import { mapGetters } from 'vuex'
import { alert } from 'frontend/lib/Noty'

export default {
  computed: {
    ...mapGetters([
      'currentUser',
    ]),
  },
  created() {
    if (!(this.currentUser.fleets || []).includes(this.$route.params.sid.toLowerCase())) {
      alert('not allowed')
      this.$router.push({
        name: 'fleet',
        params: { sid: this.$route.params.sid },
      })
    }
  },
}
</script>

<style>

</style>
