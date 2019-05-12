<template>
  <div class="hangar-guide-box">
    <Panel>
      <HangarGuide />
    </Panel>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'
import Panel from 'frontend/components/Panel'
import HangarGuide from 'frontend/partials/HangarGuide'

export default {
  components: {
    Panel,
    HangarGuide,
  },
  mixins: [I18n],
}
</script>

<style lang="scss" scoped>
  @import './styles/index';
</style>
