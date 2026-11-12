<script lang="ts">
export default {
  name: "HomeDashboardFlagship",
};
</script>

<script lang="ts" setup>
import { useHangar } from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";
import {
  dashboardHangarOptions,
  dashboardHangarParams,
} from "@/frontend/components/Home/Dashboard/hangarParams";
import { usePatchChangedTag } from "@/frontend/components/Home/Dashboard/usePatchChangedTag";

const { t } = useI18n();

const toVehicle = useVehicleRoute();

const { data } = useHangar(dashboardHangarParams, dashboardHangarOptions);

// Only a ship the pilot marked: the newest one is not a flagship by default.
const vehicle = computed(() => {
  const first = data.value?.items[0];

  return first?.flagship ? first : undefined;
});

// Only a render: the ship stands on the page itself, and a store picture's
// scene around it would need a frame again.
const image = computed(() => {
  const media = vehicle.value?.model.media;

  return media?.angledViewColored?.largeUrl || media?.angledView?.largeUrl;
});

const tagFor = usePatchChangedTag();

const tag = computed(() => (vehicle.value ? tagFor(vehicle.value) : undefined));
</script>

<template>
  <Transition name="fade-quick" appear>
    <router-link
      v-if="vehicle"
      :to="toVehicle('hangar-vehicle', vehicle)"
      class="home-flagship"
      data-test="home-flagship"
    >
      <img v-if="image" :src="image" alt="" class="home-flagship__image" />
      <span class="home-flagship__body">
        <span class="home-flagship__label">
          {{ t("labels.yourFlagship") }}
        </span>
        <span class="home-flagship__name">
          {{ vehicle.name || vehicle.model.name }}
        </span>
        <span class="home-flagship__sub">
          {{
            vehicle.name ? vehicle.model.name : vehicle.model.manufacturer?.name
          }}
        </span>
        <span
          v-if="tag"
          class="home-flagship__tag"
          data-test="home-flagship-tag"
        >
          {{ tag }}
        </span>
      </span>
    </router-link>
  </Transition>
</template>

<style lang="scss" scoped>
.home-flagship {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  min-width: 0;
  color: inherit;
  text-align: right;
  text-decoration: none;

  &:hover .home-flagship__name {
    color: var(--color-primary, #428bca);
  }
}

.home-flagship__image {
  display: block;
  width: 100%;
  max-height: 340px;
  object-fit: contain;
  object-position: right center;
}

.home-flagship__body {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 2px;
  max-width: 100%;
}

.home-flagship__label {
  color: var(--color-text-dim, #959595);
  font-size: 0.6875rem;
  font-weight: 600;
  letter-spacing: 0.08em;
  text-transform: uppercase;
}

.home-flagship__name {
  max-width: 100%;
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-family: Orbitron, sans-serif;
  font-size: 2rem;
  line-height: 1.2;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.home-flagship__sub {
  color: var(--color-text-dim, #959595);
  font-size: 0.75rem;
}

.home-flagship__tag {
  margin-top: 4px;
  padding: 2px 8px;
  border: 1px solid rgb(66 139 202 / 0.6);
  border-radius: 11px;
  background: rgb(26 29 33 / 0.9);
  color: #8dbbe3;
  font-size: 0.625rem;
  font-weight: 700;
  letter-spacing: 0.08em;
  text-transform: uppercase;
  white-space: nowrap;
}
</style>
