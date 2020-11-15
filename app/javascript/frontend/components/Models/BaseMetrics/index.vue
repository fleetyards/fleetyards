<template>
  <div class="row base-metrics metrics-padding">
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ $t('labels.metrics.base') }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.length') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.length, 'distance') }}
          </div>
          <div class="metrics-label">{{ $t('model.beam') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.beam, 'distance') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.height') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.height, 'distance') }}
          </div>
          <div class="metrics-label">{{ $t('model.mass') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.mass, 'weight') }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ $t('model.cargo') }}:</div>
          <div class="metrics-value">
            {{ $toNumber(model.cargo, 'cargo') }}
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div class="row">
        <div class="col-lg-12">
          <div class="row">
            <div class="col-6">
              <div class="metrics-label">{{ $t('model.classification') }}:</div>
              <div class="metrics-value">
                {{ model.classificationLabel }}
              </div>
            </div>
            <div class="col-6">
              <div class="metrics-label">{{ $t('model.size') }}:</div>
              <div class="metrics-value">
                {{ model.sizeLabel }}
              </div>
            </div>
          </div>
        </div>
        <div class="col-lg-12">
          <div class="row">
            <div v-if="model.price" class="col-6">
              <div class="metrics-label">{{ $t('model.price') }}:</div>
              <div
                v-tooltip="$toUEC(model.price)"
                class="metrics-value"
                v-html="$toUEC(model.price)"
              />
            </div>
            <div v-if="model.lastPledgePrice" class="col-6">
              <div class="metrics-label">{{ $t('model.pledgePrice') }}:</div>
              <div class="metrics-value">
                {{ $toDollar(model.lastPledgePrice) }}
              </div>
            </div>
          </div>
        </div>
      </div>
      <div class="row">
        <div class="col-12">
          <div class="seperator" />
        </div>
      </div>
      <div class="row">
        <div v-if="model.lastUpdatedAt" class="col-lg-12">
          <div class="metrics-label">{{ $t('model.lastUpdatedAt') }}:</div>
          <div class="metrics-value">
            {{ model.lastUpdatedAtLabel }}
          </div>
        </div>
        <div class="col-12">
          <div class="row">
            <div
              v-if="model.soldAt && model.soldAt.length"
              class="col-12 col-lg-6"
            >
              <div class="metrics-label">{{ $t('model.soldAt') }}:</div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li v-for="shop in model.soldAt" :key="shop.slug">
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
              v-if="model.rentalAt && model.rentalAt.length"
              class="col-12 col-lg-6"
            >
              <div class="metrics-label">{{ $t('model.rentalAt') }}:</div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li v-for="shop in model.rentalAt" :key="shop.slug">
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

<script lang="ts">
import Vue from 'vue'
import { Component, Prop } from 'vue-property-decorator'

@Component<BaseMetrics>({})
export default class BaseMetrics extends Vue {
  @Prop({ required: true }) model: Model
}
</script>
