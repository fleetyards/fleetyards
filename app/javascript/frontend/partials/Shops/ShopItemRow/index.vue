<template>
  <div
    :id="commodity.slug"
    class="flex-list-row"
  >
    <div class="store-image">
      <router-link
        v-if="link"
        :to="link"
      >
        <div
          v-lazy:background-image="commodity.storeImageThumb"
          :key="commodity.storeImageThumb"
          class="image"
          alt="storeImage"
        />
      </router-link>
      <div
        v-lazy:background-image="commodity.storeImageThumb"
        v-else
        :key="commodity.storeImageThumb"
        class="image"
        alt="storeImage"
      />
    </div>
    <div class="description">
      <h2>
        <router-link
          v-if="link"
          :to="link"
        >
          <span v-html="name" />
        </router-link>
        <span
          v-else
          v-html="name"
        />
        <small>{{ commodity.subCategoryLabel }}</small>
      </h2>
      <div
        v-if="showStats"
        class="row"
      >
        <div class="col-xs-12 col-md-6">
          <ul class="list-unstyled">
            <li v-if="commodity.item.grade">
              <b>{{ t('commodityItem.grade') }}:</b> {{ commodity.item.grade }}
            </li>
            <li v-if="commodity.item.size">
              <b>{{ t('commodityItem.size') }}:</b> {{ commodity.item.size }}
            </li>
            <li v-if="commodity.item.typeLabel">
              <b>{{ t('commodityItem.type') }}:</b> {{ commodity.item.typeLabel }}
            </li>
            <li v-if="commodity.item.itemTypeLabel">
              <b>{{ t('commodityItem.itemType') }}:</b> {{ commodity.item.itemTypeLabel }}
            </li>
            <li v-if="commodity.item.weaponClassLabel">
              <b>{{ t('commodityItem.weaponClass') }}:</b> {{ commodity.item.weaponClassLabel }}
            </li>
          </ul>
        </div>
        <div class="col-xs-12 col-md-6">
          <ul class="list-unstyled">
            <li v-if="commodity.item.range">
              <b>{{ t('commodityItem.range') }}:</b>
              {{ toNumber(commodity.item.range, 'distance') }}
            </li>
            <li v-if="commodity.item.damageReduction">
              <b>{{ t('commodityItem.damageReduction') }}:</b>
              {{ toNumber(commodity.item.damageReduction, 'percent') }}
            </li>
            <li v-if="commodity.item.rateOfFire">
              <b>{{ t('commodityItem.rateOfFire') }}:</b>
              {{ toNumber(commodity.item.rateOfFire, 'rateOfFire') }}
            </li>
            <li v-if="commodity.item.extras">{{ commodity.item.extras }}</li>
          </ul>
        </div>
      </div>
      {{ commodity.description }}
    </div>
    <div
      v-if="selling"
      class="price"
    >
      <span class="price-label">{{ t('labels.shop.sellPrice') }}:&nbsp;</span>
      {{ toUEC(commodity.sellPrice) }}
    </div>
    <div
      v-if="buying"
      class="price"
    >
      <span class="price-label">{{ t('labels.shop.buyPrice') }}:&nbsp;</span>
      {{ toUEC(commodity.buyPrice) }}
    </div>
    <div
      v-if="rental"
      class="rent-price"
    >
      <span class="price-label">{{ t('labels.shop.rentPrice') }}:&nbsp;</span>
      {{ t('shop.rentalPrice', { price: toUEC(commodity.rentPrice) }) }}
    </div>
  </div>
</template>

<script>
import I18n from 'frontend/mixins/I18n'

export default {
  mixins: [I18n],
  props: {
    commodity: {
      type: Object,
      required: true,
    },
    rental: {
      type: Boolean,
      default: false,
    },
    selling: {
      type: Boolean,
      default: false,
    },
    buying: {
      type: Boolean,
      default: false,
    },
  },
  computed: {
    showStats() {
      return ['equipment', 'component'].includes(this.commodity.category)
    },
    manufacturer() {
      if (!this.commodity.item || !this.commodity.item.manufacturer) {
        return null
      }
      return this.commodity.item.manufacturer
    },
    name() {
      if (this.manufacturer) {
        if (this.manufacturer.code) {
          return `${this.manufacturer.code} ${this.commodity.name}`
        }
        return `${this.manufacturer.name} ${this.commodity.name}`
      }
      return this.commodity.name
    },
    link() {
      if (this.commodity.category !== 'model') {
        return null
      }
      return {
        name: 'model',
        params: {
          slug: this.commodity.slug,
        },
      }
    },
  },
}
</script>

<style>

</style>
