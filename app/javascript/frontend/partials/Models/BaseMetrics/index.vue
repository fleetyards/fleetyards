<template>
  <div
    class="row base-metrics"
    :class="{
      'metrics-padding': padding,
    }"
  >
    <div
      v-if="title"
      :class="{
        'col-md-3': title,
      }"
      class="col-xs-12"
    >
      <div class="metrics-title">
        {{ $t('labels.metrics.base') }}
      </div>
    </div>
    <div
      :class="{
        'col-md-9': title,
      }"
      class="col-xs-12 metrics-block"
    >
      <div class="row">
        <div class="col-xs-6 col-md-4">
          <div class="metrics-label">
            {{ $t('model.length') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(model.length, 'distance') }}
          </div>
          <div class="metrics-label">
            {{ $t('model.beam') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(model.beam, 'distance') }}
          </div>
          <template v-if="detailed">
            <div class="metrics-label">
              {{ $t('model.classification') }}:
            </div>
            <div class="metrics-value">
              {{ model.classificationLabel }}
            </div>
          </template>
        </div>
        <div class="col-xs-6 col-md-4">
          <div class="metrics-label">
            {{ $t('model.height') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(model.height, 'distance') }}
          </div>
          <div class="metrics-label">
            {{ $t('model.mass') }}:
          </div>
          <div class="metrics-value">
            {{ $toNumber(model.mass, 'weight') }}
          </div>
          <template v-if="detailed">
            <div class="metrics-label">
              {{ $t('model.size') }}:
            </div>
            <div class="metrics-value">
              {{ model.sizeLabel }}
            </div>
          </template>
        </div>
        <div class="col-xs-12 col-md-4">
          <div class="row">
            <div class="col-xs-6 col-md-12">
              <div class="metrics-label">
                {{ $t('model.cargo') }}:
              </div>
              <div class="metrics-value">
                {{ $toNumber(model.cargo, 'cargo') }}
              </div>
            </div>
            <div
              v-if="model.price"
              class="col-xs-6 col-md-12"
            >
              <div class="metrics-label">
                {{ $t('model.price') }}:
              </div>
              <div class="metrics-value">
                {{ $toUEC(model.price) }}
              </div>
            </div>
            <div
              v-if="detailed && model.lastPledgePrice"
              class="col-xs-6 col-md-12"
            >
              <div class="metrics-label">
                {{ $t('model.pledgePrice') }}:
              </div>
              <div class="metrics-value">
                {{ $toDollar(model.lastPledgePrice) }}
              </div>
            </div>
          </div>
        </div>
        <div
          v-if="detailed && model.lastUpdatedAt"
          class="col-md-12"
        >
          <div class="metrics-label">
            {{ $t('model.lastUpdatedAt') }}:
          </div>
          <div class="metrics-value">
            {{ model.lastUpdatedAtLabel }}
          </div>
        </div>
        <div class="col-xs-12">
          <div class="row">
            <div
              v-if="detailed && model.soldAt && model.soldAt.length"
              class="col-xs-12 col-md-6"
            >
              <div class="metrics-label">
                {{ $t('model.soldAt') }}:
              </div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li
                    v-for="shop in model.soldAt"
                    :key="shop.slug"
                  >
                    <router-link
                      :to="{
                        name: 'shop',
                        params: {
                          station: shop.stationSlug,
                          slug: shop.slug,
                        },
                      }"
                    >
                      {{ shop.name }}
                    </router-link>
                  </li>
                </ul>
              </div>
            </div>
            <div
              v-if="detailed && model.rentalAt && model.rentalAt.length"
              class="col-xs-12 col-md-6"
            >
              <div class="metrics-label">
                {{ $t('model.rentalAt') }}:
              </div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li
                    v-for="shop in model.rentalAt"
                    :key="shop.slug"
                  >
                    <router-link
                      :to="{
                        name: 'shop',
                        params: {
                          station: shop.stationSlug,
                          slug: shop.slug,
                        },
                      }"
                    >
                      {{ shop.name }}
                    </router-link>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
export default {
  props: {
    model: {
      type: Object,
      required: true,
    },

    title: {
      type: Boolean,
      default: false,
    },

    detailed: {
      type: Boolean,
      default: false,
    },

    padding: {
      type: Boolean,
      default: false,
    },
  },
}
</script>

<style lang="scss" scoped>
  @import 'index';
</style>
