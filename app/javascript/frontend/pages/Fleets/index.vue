<template>
  <router-view />
</template>

<script>
export default {
  name: 'Fleets',

  mounted() {
    if (this.$route.name === 'fleets') {
      if (this.currentUser && this.currentUser.fleets[0]) {
        const fleet = this.currentUser.fleets[0]
        this.$router.push({ name: 'fleet', params: { slug: fleet.slug } })
      } else {
        this.$router.push({ name: 'home' })
      }
    }
  },
}
</script>
