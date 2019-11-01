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
          :key="commodity.storeImageSmall"
          v-lazy:background-image="commodity.storeImageSmall"
          class="image lazy"
          alt="storeImage"
        />
      </router-link>
      <div
        v-else
        :key="commodity.storeImageSmall"
        v-lazy:background-image="commodity.storeImageSmall"
        class="image lazy"
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
              <b>{{ $t('commodityItem.grade') }}:</b> {{ commodity.item.grade }}
            </li>
            <li v-if="commodity.item.size">
              <b>{{ $t('commodityItem.size') }}:</b> {{ commodity.item.size }}
            </li>
            <li v-if="commodity.item.typeLabel">
              <b>{{ $t('commodityItem.type') }}:</b> {{ commodity.item.typeLabel }}
            </li>
            <li v-if="commodity.item.itemTypeLabel">
              <b>{{ $t('commodityItem.itemType') }}:</b> {{ commodity.item.itemTypeLabel }}
            </li>
            <li v-if="commodity.item.weaponClassLabel">
              <b>{{ $t('commodityItem.weaponClass') }}:</b> {{ commodity.item.weaponClassLabel }}
            </li>
            <li v-if="commodity.item.itemClassLabel">
              <b>{{ $t('commodityItem.itemClass') }}:</b> {{ commodity.item.itemClassLabel }}
            </li>
          </ul>
        </div>
        <div class="col-xs-12 col-md-6">
          <ul class="list-unstyled">
            <li v-if="commodity.item.range">
              <b>{{ $t('commodityItem.range') }}:</b>
              {{ $toNumber(commodity.item.range, 'distance') }}
            </li>
            <li v-if="commodity.item.damageReduction">
              <b>{{ $t('commodityItem.damageReduction') }}:</b>
              {{ $toNumber(commodity.item.damageReduction, 'percent') }}
            </li>
            <li v-if="commodity.item.rateOfFire">
              <b>{{ $t('commodityItem.rateOfFire') }}:</b>
              {{ $toNumber(commodity.item.rateOfFire, 'rateOfFire') }}
            </li>
            <li v-if="commodity.item.extras">
              {{ commodity.item.extras }}
            </li>
          </ul>
        </div>
      </div>
      {{ commodity.description }}
    </div>
    <div
      v-if="selling"
      class="price"
    >
      <span class="price-label">
        {{ $t('labels.shop.sellPrice') }}:&nbsp;
      </span>
      <b>{{ $toUEC(commodity.sellPrice) }}</b>
    </div>
    <div
      v-if="buying"
      class="price"
    >
      <span class="price-label">
        {{ $t('labels.shop.buyPrice') }}:&nbsp;
      </span>
      <b>{{ $toUEC(commodity.buyPrice) }}</b>
    </div>
    <div
      v-if="rental"
      class="rent-price"
    >
      <span class="price-label">
        {{ $t('labels.shop.rentPrice') }}:&nbsp;
      </span>
      <ul class="list-unstyled">
        <li v-if="commodity.rentPrice1Day">
          {{ $t('shop.rentalPrice1Day') }} <b>{{ $toUEC(commodity.rentPrice1Day) }}</b>
        </li>
        <li v-if="commodity.rentPrice3Days">
          {{ $t('shop.rentalPrice3Days') }} <b>{{ $toUEC(commodity.rentPrice3Days) }}</b>
        </li>
        <li v-if="commodity.rentPrice7Days">
          {{ $t('shop.rentalPrice7Days') }} <b>{{ $toUEC(commodity.rentPrice7Days) }}</b>
        </li>
        <li v-if="commodity.rentPrice30Days">
          {{ $t('shop.rentalPrice30Days') }} <b>{{ $toUEC(commodity.rentPrice30Days) }}</b>
        </li>
      </ul>
    </div>
  </div>
</template>

<script>
export default {
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
