<template>
  <section class="container">
    <div class="row">
      <div class="col-12">
        <h1>{{ $t('headlines.tools.profitCalculator.index') }}</h1>
      </div>
    </div>
    <div class="row">
      <div class="col-12"></div>
    </div>
  </section>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import MetaInfo from 'frontend/mixins/MetaInfo'

@Component<ProfitCalculator>({
  components: {},

  mixins: [MetaInfo],
})
export default class ProfitCalculator extends Vue {}
</script>
