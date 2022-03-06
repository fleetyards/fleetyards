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

<script>
import MetaInfo from '@/frontend/mixins/MetaInfo'

export default {
  name: 'ProfitCalculator',
  mixins: [MetaInfo],
}
</script>
