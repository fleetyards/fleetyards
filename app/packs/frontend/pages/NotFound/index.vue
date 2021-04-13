<template>
  <div class="container">
    <Box class="error" :large="true">
      <h1>{{ $t('headlines.error') }}</h1>
      <p>{{ $t('texts.error') }}</p>
      <template #footer>
        <Btn :to="{ name: 'home' }" :exact="true">
          <i class="fa fa-chevron-left" />
          {{ $t('actions.backToHome').toUpperCase() }}
        </Btn>
      </template>
    </Box>
  </div>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'
import Box from 'frontend/core/components/Box'
import Btn from 'frontend/core/components/Btn'

@Component<NotFound>({
  components: {
    Box,
    Btn,
  },
  mixins: [MetaInfo],
})
export default class NotFound extends Vue {}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
