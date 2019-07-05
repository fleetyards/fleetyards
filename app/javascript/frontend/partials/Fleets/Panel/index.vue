<template>
  <Panel>
    <div class="panel-fleet">
      <div class="logo">
        <img :src="fleet.logo">
      </div>
      <div class="inner">
        <h3>
          <router-link :to="{ name: 'fleet', params: { sid: fleet.sid } }">
            {{ fleet.name }} ({{ fleet.sid }})
          </router-link>
        </h3>
        <div class="subline">
          {{ $t('labels.fleet.memberCount', { count: fleet.memberCount }) }}
        </div>
        <div class="activities">
          <img
            v-tooltip="fleet.mainActivity"
            :src="acitivtyIcons[fleet.mainActivity]"
          >
          <img
            v-tooltip="fleet.secondaryActivity"
            :src="acitivtyIcons[fleet.secondaryActivity]"
          >
        </div>
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'

export default {
  components: {
    Panel,
  },
  props: {
    fleet: {
      type: Object,
      required: true,
    },
  },
  data() {
    return {
      acitivtyIcons: {
        /* eslint-disable global-require */
        BountyHunting: require('images/org-icons/bountyhunting.png'),
        Freelancing: require('images/org-icons/freelancing.png'),
        Trading: require('images/org-icons/trade.png'),
        Social: require('images/org-icons/social.png'),
        Engineering: require('images/org-icons/engineering.png'),
        Piracy: require('images/org-icons/piracy.png'),
        Infiltration: require('images/org-icons/infiltration.png'),
        Exploration: require('images/org-icons/exploration.png'),
        Resources: require('images/org-icons/resources.png'),
        Scouting: require('images/org-icons/scouting.png'),
        Security: require('images/org-icons/security.png'),
        Smuggling: require('images/org-icons/smuggling.png'),
        Transport: require('images/org-icons/transport.png'),
        /* eslint-enable global-require */
      },
    }
  },
}
</script>

<style lang="scss" scoped>
  @import './index';
</style>
