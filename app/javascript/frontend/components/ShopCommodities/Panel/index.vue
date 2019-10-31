<template>
  <Panel>
    <div class="teaser-panel">
      <LazyImage
        :to="route"
        :src="item.storeImageMedium"
        class="teaser-panel-image"
      />
      <div class="teaser-panel-body">
        <h3 v-tooltip="item.name">
          <router-link :to="route">
            {{ item.name }}
          </router-link>
        </h3>
        <ul
          v-if="showStats"
          class="list-unstyled"
        >
          <li>
            <b>{{ $t('commodityItem.grade') }}:</b> {{ item.item.grade || '-' }}
          </li>
          <li>
            <b>{{ $t('commodityItem.size') }}:</b> {{ item.item.size || '-' }}
          </li>
          <li>
            <b>{{ $t('commodityItem.type') }}:</b> {{ item.item.typeLabel || '-' }}
          </li>
          <li>
            <b>{{ $t('commodityItem.itemType') }}:</b> {{ item.item.itemTypeLabel || '-' }}
          </li>
          <li v-if="item.category === 'equipment'">
            <b>{{ $t('commodityItem.weaponClass') }}:</b> {{ item.item.weaponClassLabel || '-' }}
          </li>
          <li v-else>
            <b>{{ $t('commodityItem.itemClass') }}:</b> {{ item.item.itemClassLabel || '-' }}
          </li>
          <li v-if="item.category === 'equipment'">
            <b>{{ $t('commodityItem.range') }}:</b>
            {{ $toNumber(item.item.range, 'distance') }}
          </li>
          <li v-if="item.category === 'equipment'">
            <b>{{ $t('commodityItem.damageReduction') }}:</b>
            {{ $toNumber(item.item.damageReduction, 'percent') }}
          </li>
          <li v-if="item.category === 'equipment'">
            <b>{{ $t('commodityItem.rateOfFire') }}:</b>
            {{ $toNumber(item.item.rateOfFire, 'rateOfFire') }}
          </li>
        </ul>
        {{ item.item.extras }}
      </div>
    </div>
  </Panel>
</template>

<script>
import Panel from 'frontend/components/Panel'
import LazyImage from 'frontend/components/LazyImage'

export default {
  components: {
    Panel,
    LazyImage,
  },

  props: {
    item: {
      type: Object,
      required: true,
    },
  },

  computed: {
    showStats() {
      return ['equipment', 'component'].includes(this.item.category)
    },

    route() {
      return { name: 'shop', params: { station: this.item.shop.station.slug, slug: this.item.shop.slug } }
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
