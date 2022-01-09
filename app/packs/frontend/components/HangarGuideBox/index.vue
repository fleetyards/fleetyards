<template>
  <div class="hangar-guide-box">
    <Panel>
      <HangarGuide />
    </Panel>
  </div>
</template>

<script>
import Panel from 'frontend/core/components/Panel'
import HangarGuide from 'frontend/components/HangarGuide'

export default {
  name: 'HangarGuideBox',

  components: {
    Panel,
    HangarGuide,
  },
}
</script>

<style lang="scss" scoped>
@import './styles/index';
</style>
