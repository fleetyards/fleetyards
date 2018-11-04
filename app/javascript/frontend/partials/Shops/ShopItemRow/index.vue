<template>
  <tr
    :id="commodity.slug"
    class="fade-item"
  >
    <td class="store-image">
      <router-link
        v-if="link"
        :to="link"
      >
        <div
          v-lazy:background-image="commodity.storeImage"
          :key="commodity.storeImage"
          class="image"
          alt="storeImage"
        />
      </router-link>
      <div
        v-lazy:background-image="commodity.storeImage"
        v-else
        :key="commodity.storeImage"
        class="image"
        alt="storeImage"
      />
    </td>
    <td class="description">
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
            <li
              v-for="item in leftStatItems"
              :key="item.key"
            >
              <b v-if="item.label">{{ item.label }}</b>{{ item.value }}
            </li>
          </ul>
        </div>
        <div class="col-xs-12 col-md-6">
          <ul class="list-unstyled">
            <li
              v-for="item in rightStatItems"
              :key="item.key"
            >
              <b v-if="item.label">{{ item.label }}</b>{{ item.value }}
            </li>
          </ul>
        </div>
      </div>
      {{ commodity.description }}
    </td>
    <td
      v-if="selling"
      class="price"
    >
      {{ toUEC(commodity.sellPrice) }}
    </td>
    <td
      v-if="buying"
      class="price"
    >
      {{ toUEC(commodity.buyPrice) }}
    </td>
    <td
      v-if="rental"
      class="price"
    >
      {{ t('shop.rentalPrice', { price: toUEC(commodity.rentPrice) }) }}
    </td>
  </tr>
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
    leftStatItems() {
      return ['grade', 'size', 'type', 'itemType', 'weaponClass'].map(this.statItem).filter(item => item)
    },
    rightStatItems() {
      return ['range', 'damageReduction', 'rateOfFire', 'extras'].map(this.statItem).filter(item => item)
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
  methods: {
    statItem(item) {
      const value = this.commodity.item[`${item}Label`] || this.commodity.item[item]
      if (!value) {
        return null
      }

      let label = this.t(`commodityItem.${item}`)
      if (label) {
        label = `${label}: `
      }

      return {
        key: item,
        label,
        value,
      }
    },
  },
}
</script>

<style>

</style>
