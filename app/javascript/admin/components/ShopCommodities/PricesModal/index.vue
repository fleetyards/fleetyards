<template>
  <ValidationObserver v-slot="{ handleSubmit }" :small="true" :slim="true">
    <Modal v-if="shopCommodity" :title="title" class="prices-modal">
      <div
        v-for="record in collection.records"
        :key="record.id"
        class="price-item"
      >
        <FormInput
          :id="record.id"
          class="input"
          type="number"
          :disabled="true"
          :value="record.price"
          :no-label="true"
        />
        <span v-if="record.timeRange" class="time-range-label">
          {{ record.timeRange }}
        </span>
        <span class="date-label">
          {{ $l(record.createdAt) }}
        </span>
        <Btn size="small" @click.native="destroy(record)">
          <i class="fa fa-times" />
        </Btn>
      </div>
      <div v-if="form" class="new-price">
        <ValidationProvider
          v-slot="{ errors }"
          vid="price"
          rules="required"
          :name="$t('labels.price')"
          :slim="true"
        >
          <FormInput
            id="new-price"
            v-model="form.price"
            :error="errors[0]"
            class="input"
            type="number"
            :no-label="true"
            translation-key="commodityPrice.price"
          />
        </ValidationProvider>
        <ValidationProvider
          v-if="path === 'rental'"
          v-slot="{ errors }"
          vid="timeRange"
          rules="required"
          :name="$t('labels.timeRange')"
          :slim="true"
        >
          <FilterGroup
            v-model="form.timeRange"
            name="time-range"
            :error="errors[0]"
            :options="timeRanges"
            :no-label="true"
          />
        </ValidationProvider>
        <Btn size="small" @click.native="handleSubmit(create)">
          <i class="fa fa-check" />
        </Btn>
      </div>
    </Modal>
  </ValidationObserver>
</template>

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'
import Modal from 'frontend/core/components/AppModal/Modal'
import commodityPricesCollection from 'admin/api/collections/CommodityPrices'
import FormInput from 'frontend/core/components/Form/FormInput'
import FilterGroup from 'frontend/core/components/Form/FilterGroup'
import Btn from 'frontend/core/components/Btn'

@Component<BuyPricesModal>({
  components: {
    Modal,
    FormInput,
    Btn,
    FilterGroup,
  },
})
export default class BuyPricesModal extends Vue {
  @Prop({ required: true }) shopId: string

  @Prop({ required: true }) path: string

  @Prop({ required: true }) shopCommodity: ShopCommodity

  collection: CommodityPricesCollection = commodityPricesCollection

  prices: ShopCommodityPrice[] = []

  form: AdminCommodityPriceForm = null

  timeRanges = commodityPricesCollection.timeRanges.map(item => ({
    value: item,
    name: item,
  }))

  get title() {
    return this.$t(`headlines.modals.shopCommodity.${this.path}Prices`, {
      shopCommodity: this.shopCommodity.item.name,
    })
  }

  get params() {
    return {
      shopId: this.shopId,
      shopCommodityId: this.shopCommodity.id,
      path: this.path,
    }
  }

  mounted() {
    this.fetch()
    this.setupForm()
  }

  setupForm() {
    this.form = {
      shopCommodityId: this.shopCommodity.id,
      path: this.path,
      price: null,
    }
  }

  async fetch() {
    await this.collection.findAll(this.params)
  }

  async create() {
    await this.collection.create(this.form)

    this.$comlink.$emit('prices-update')

    this.newPrice = null
  }

  async destroy(record) {
    await this.collection.destroy(record.id)

    this.$comlink.$emit('prices-update')

    this.fetch()
  }
}
</script>
