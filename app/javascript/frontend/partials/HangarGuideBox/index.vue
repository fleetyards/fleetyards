<template>
  <div class="hangar-guide-box">
    <Panel>
      <HangarGuide />
    </Panel>
  </div>
</template>

<script>
import Panel from 'frontend/components/Panel'
import HangarGuide from 'frontend/partials/HangarGuide'

export default {
  components: {
    Panel,
    HangarGuide,
  },
}
</script>

<style lang="scss" scoped>
@import './styles/index';
</style>
