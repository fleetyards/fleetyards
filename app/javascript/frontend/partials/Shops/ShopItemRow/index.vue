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
    name() {
      if (this.commodity.manufacturer) {
        if (this.commodity.manufacturer.code) {
          return `${this.commodity.manufacturer.code} ${this.commodity.name}`
        }
        return `${this.commodity.manufacturer.name} ${this.commodity.name}`
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
