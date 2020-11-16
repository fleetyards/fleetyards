<template>
  <Modal :title="$t('headlines.shoppingCart')">
    <div class="shopping-cart">
      <div v-if="cartItems.length" class="item-list">
        <div class="item-list-item item-list-header">
          <div class="item-name"></div>
          <div class="item-amount"></div>
          <div class="item-sold-at">per Item</div>
          <div class="item-price">Item Total</div>
          <div class="item-actions"></div>
        </div>
        <div
          v-for="(items, id) in groupedItems"
          :key="id"
          class="item-list-item"
        >
          <div class="item-name">{{ items[0].name }}</div>
          <div class="item-amount noselect">
            <i
              :key="`remove-item-${id}`"
              class="fal fa-minus"
              :class="{
                disabled: items.length <= 1,
              }"
              @click="removeItem(items)"
            />
            <span>
              {{ items.length }}
              <i class="fal fa-times" />
            </span>
            <i
              :key="`add-item-${id}`"
              class="fal fa-plus"
              @click="addItem(items)"
            />
          </div>
          <div class="item-sold-at">
            <ul class="list-unstyled">
              <li v-for="item in soldAt(items)" :key="`${id}-${item.id}`">
                <div>
                  {{ item.shop.station.name }}
                  <span class="text-darken">{{ item.shop.name }}</span>
                </div>
                <span v-html="$toUEC(item.sellPrice)" />
              </li>
            </ul>
          </div>
          <template v-if="soldAt(items).length">
            <div class="item-price" v-html="$toUEC(sum(items))" />
          </template>
          <div v-else class="item-price unavailable">
            {{ $t('labels.unavailable') }}
          </div>
          <div class="item-actions">
            <Btn :inline="true" size="small" @click.native="remove(items)">
              <i class="fal fa-trash" />
            </Btn>
          </div>
        </div>
        <div key="total" class="item-list-item item-list-total">
          <div class="text-darken">{{ $t('labels.shoppingCart.total') }}</div>
          <div v-html="$toUEC(total)" />
        </div>
      </div>
      <div v-else class="item-list-empty">
        {{ $t('labels.blank.shoppingCart') }}
      </div>
    </div>

    <template #footer>
      <div class="float-sm-right">
        <Btn
          :inline="true"
          :disabled="!cartItems.length"
          @click.native="clearCart"
        >
          {{ $t('actions.shoppingCart.clear') }}
        </Btn>
        <Btn :inline="true" @click.native="closeModal">
          {{ $t('actions.close') }}
        </Btn>
      </div>
    </template>
  </Modal>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component } from 'vue-property-decorator'
import { Getter, Action } from 'vuex-class'
import Modal from 'frontend/core/components/AppModal/Modal'
import Btn from 'frontend/core/components/Btn'
import { sum } from 'frontend/utils/Array'
import { groupBy, sortBy } from 'frontend/lib/Helpers'

@Component<ShoppingCart>({
  components: {
    Modal,
    Btn,
  },
})
export default class ShoppingCart extends Vue {
  @Getter('navSlim', { namespace: 'app' }) navSlim: boolean

  @Getter('items', { namespace: 'shoppingCart' }) cartItems: any[]

  @Action('clear', { namespace: 'shoppingCart' }) clearCart: any

  @Action('add', { namespace: 'shoppingCart' }) addToCart: any

  @Action('remove', { namespace: 'shoppingCart' }) removeFromCart: any

  get groupedItems() {
    return groupBy(sortBy(this.cartItems, 'name'), 'id')
  }

  get sellPrices() {
    return this.cartItems
      .map(item => item.bestSoldAt)
      .map(item => parseFloat(item?.sellPrice))
      .filter(item => item)
  }

  get total() {
    return sum(this.sellPrices)
  }

  soldAt(items) {
    return items[0].soldAt || []
  }

  sum(items) {
    return sum(
      items
        .map(item => item.bestSoldAt)
        .map(item => parseFloat(item?.sellPrice))
        .filter(item => item),
    )
  }

  remove(items) {
    items.forEach(item => {
      this.removeFromCart(item)
    })
  }

  addItem(items) {
    if (items.length < 1) {
      return
    }

    this.addToCart(items[0])
  }

  removeItem(items) {
    if (items.length <= 1) {
      return
    }

    this.removeFromCart(items[0])
  }

  closeModal() {
    this.$comlink.$emit('close-modal')
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
