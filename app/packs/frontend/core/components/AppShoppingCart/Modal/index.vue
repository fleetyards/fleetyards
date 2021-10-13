<template>
  <Modal :title="$t('headlines.shoppingCart')">
    <div class="shopping-cart">
      <div v-if="cartItems.length" class="item-list">
        <div class="item-list-item item-list-header">
          <div class="item-name"></div>

          <div class="item-amount"></div>

          <div class="item-sold-at">
            {{ $t('labels.shoppingCart.perItem') }}
          </div>

          <div class="item-price">
            {{ $t('labels.shoppingCart.itemTotal') }}
          </div>

          <div class="item-actions"></div>
        </div>
        <div
          v-for="cartItem in sortedItems"
          :key="cartItem.id"
          class="item-list-item"
        >
          <div class="item-name">{{ cartItem.name }}</div>

          <ItemAmount v-if="!mobile" :cart-item="cartItem" />

          <div class="item-sold-at">
            <ul class="list-unstyled">
              <li
                v-for="soldAt in cartItem.soldAt"
                :key="`${cartItem.id}-${soldAt.id}`"
              >
                <div>
                  {{ soldAt.stationName }}
                  <span class="text-muted">{{ soldAt.shopName }}</span>
                </div>
                <span class="price-label" v-html="$toUEC(soldAt.price)" />
              </li>
            </ul>
            <ul class="list-unstyled">
              <li
                v-for="listedAt in cartItem.listedAt"
                :key="`${cartItem.id}-${listedAt.id}`"
              >
                <div>
                  {{ listedAt.stationName }}
                  <span class="text-muted">{{ listedAt.shopName }}</span>
                </div>
                <span class="price-label">
                  -
                </span>
              </li>
            </ul>
          </div>

          <div
            v-if="cartItem.soldAt.length"
            class="item-price price-label"
            v-html="$toUEC(sum(cartItem))"
          />

          <div v-else class="item-price unavailable">
            {{ $t('labels.unavailable') }}
          </div>

          <div class="item-actions">
            <ItemAmount v-if="mobile" :cart-item="cartItem" />
            <Btn
              :inline="true"
              size="small"
              variant="link"
              @click.native="removeFromCart(cartItem.id)"
            >
              <i class="fal fa-trash" />
            </Btn>
          </div>
        </div>
        <div key="total" class="item-list-item item-list-total">
          <div class="text-muted">{{ $t('labels.shoppingCart.total') }}</div>
          <div class="price-label" v-html="$toUEC(total)" />
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
          :disabled="!cartItems.length || loading"
          :loading="loading"
          :aria-label="$t('actions.shoppingCart.refresh')"
          @click.native="refresh"
        >
          <i class="fad fa-sync" />
        </Btn>
        <Btn
          :inline="true"
          :disabled="!cartItems.length"
          :aria-label="$t('actions.shoppingCart.clear')"
          @click.native="clearCart"
        >
          <i class="fad fa-trash" />
        </Btn>
        <Btn
          :inline="true"
          :aria-label="$t('actions.close')"
          @click.native="closeModal"
        >
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
import { sum as sumArray } from 'frontend/utils/Array'
import { sortBy } from 'frontend/lib/Helpers'
import ItemAmount from 'frontend/core/components/AppShoppingCart/ItemAmount'
import ComponentsCollection from 'frontend/api/collections/Components'
import CommoditiesCollection from 'frontend/api/collections/Commodities'
import EquipmentCollection from 'frontend/api/collections/Equipment'
import ModelsCollection from 'frontend/api/collections/Models'
// import ModelPaintsCollection from 'frontend/api/collections/ModelPaints'
// import ModelModulesCollection from 'frontend/api/collections/ModelModules'

@Component<ShoppingCart>({
  components: {
    Modal,
    Btn,
    ItemAmount,
  },
})
export default class ShoppingCart extends Vue {
  @Getter('mobile') mobile: boolean

  @Getter('items', { namespace: 'shoppingCart' }) cartItems: any[]

  @Action('clear', { namespace: 'shoppingCart' }) clearCart: any

  @Action('update', { namespace: 'shoppingCart' }) updateInCart: any

  @Action('remove', { namespace: 'shoppingCart' }) removeFromCart: any

  loading: boolean = false

  get sortedItems() {
    return sortBy(this.cartItems, 'name')
  }

  get total() {
    return sumArray(
      this.cartItems.map(item => this.sum(item)).filter(item => item),
    )
  }

  sum(cartItem) {
    return parseFloat((cartItem.bestSoldAt?.price || 0) * cartItem.amount)
  }

  closeModal() {
    this.$comlink.$emit('close-modal')
  }

  async refreshForType(collection, type) {
    const items = await collection.findAll({
      filters: {
        idIn: this.cartItems
          .filter(item => item.type === type)
          .map(item => item.id),
      },
    })

    items.forEach(item => this.updateInCart({ item, type }))
  }

  async refresh() {
    this.loading = true
    await this.refreshForType(ComponentsCollection, 'Component')
    await this.refreshForType(CommoditiesCollection, 'Commodity')
    await this.refreshForType(EquipmentCollection, 'Equipment')
    await this.refreshForType(ModelsCollection, 'Model')
    // await this.refreshForType(ModelPaintsCollection, 'ModelPaint')
    // await this.refreshForType(ModelModulesCollection, 'ModelModule')
    this.loading = false
  }
}
</script>

<style lang="scss" scoped>
@import 'index';
</style>
