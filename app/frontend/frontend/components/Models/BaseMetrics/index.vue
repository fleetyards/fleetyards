<template>
  <div class="row base-metrics metrics-padding">
    <div class="col-12 col-lg-3">
      <div class="metrics-title">
        {{ t("labels.metrics.base") }}
      </div>
    </div>
    <div class="col-12 col-lg-9 metrics-block">
      <div class="row">
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.length") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.length || "", "distance") }}
          </div>
          <div class="metrics-label">{{ t("model.beam") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.beam || "", "distance") }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.height") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.height || "", "distance") }}
          </div>
          <div class="metrics-label">{{ t("model.mass") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.mass || "", "weight") }}
          </div>
        </div>
        <div class="col-6 col-lg-4">
          <div class="metrics-label">{{ t("model.cargo") }}:</div>
          <div class="metrics-value">
            {{ toNumber(model.metrics.cargo || "", "cargo") }}
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
              <div class="metrics-label">{{ t("model.classification") }}:</div>
              <div class="metrics-value">
                {{ model.classificationLabel }}
              </div>
            </div>
            <div class="col-6">
              <div class="metrics-label">{{ t("model.size") }}:</div>
              <div class="metrics-value">
                {{ model.metrics.sizeLabel }}
              </div>
            </div>
          </div>
        </div>
        <div class="col-lg-12">
          <div class="row">
            <div v-if="model.price" class="col-6">
              <div class="metrics-label">{{ t("model.price") }}:</div>
              <div
                v-tooltip="toUEC(model.price)"
                class="metrics-value"
                v-html="toUEC(model.price)"
              />
            </div>
            <div v-if="model.lastPledgePrice" class="col-6">
              <div class="metrics-label">{{ t("model.pledgePrice") }}:</div>
              <div class="metrics-value">
                {{ toDollar(model.lastPledgePrice) }}
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
        <div class="col-lg-12">
          <div class="row">
            <div v-if="model.metrics.hydrogenFuelTankSize" class="col-6">
              <div class="metrics-label">
                {{ t("model.hydrogenFuelTankSize") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(model.metrics.hydrogenFuelTankSize, "fuel") }}
              </div>
            </div>
            <div v-if="model.metrics.quantumFuelTankSize" class="col-6">
              <div class="metrics-label">
                {{ t("model.quantumFuelTankSize") }}:
              </div>
              <div class="metrics-value">
                {{ toNumber(model.metrics.quantumFuelTankSize, "fuel") }}
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
          <div class="metrics-label">{{ t("model.lastUpdatedAt") }}:</div>
          <div class="metrics-value">
            {{ model.lastUpdatedAtLabel }}
          </div>
        </div>
        <div class="col-12">
          <div class="row">
            <div v-if="soldAt && soldAt.length" class="col-12 col-lg-6">
              <div class="metrics-label">{{ t("model.soldAt") }}:</div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li v-for="shopCommodity in soldAt" :key="shopCommodity.id">
                    <router-link :to="shopRoute(shopCommodity)">
                      {{ shopName(shopCommodity) }}
                    </router-link>
                  </li>
                </ul>
              </div>
            </div>
            <div v-if="rentalAt && rentalAt.length" class="col-12 col-lg-6">
              <div class="metrics-label">{{ t("model.rentalAt") }}:</div>
              <div class="metrics-value">
                <ul class="list-unstyled">
                  <li v-for="shopCommodity in rentalAt" :key="shopCommodity.id">
                    <router-link :to="shopRoute(shopCommodity)">
                      {{ shopName(shopCommodity) }}
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

<script lang="ts" setup>
import type { Model, ShopCommodity } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";

const { t, toNumber, toDollar, toUEC } = useI18n();

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const shopRoute = (shopCommodity: ShopCommodity) => ({
  name: "shop",
  params: {
    stationSlug: shopCommodity.shop?.station?.slug,
    slug: shopCommodity.shop?.slug,
  },
});

const shopName = (shopCommodity: ShopCommodity) => shopCommodity.shop?.name;

const soldAt = computed(() => props.model.availability.soldAt);
const rentalAt = computed(() => props.model.availability.rentalAt);
</script>

<script lang="ts">
export default {
  name: "ModelBaseMetrics",
};
</script>
