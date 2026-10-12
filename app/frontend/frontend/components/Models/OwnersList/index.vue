<script lang="ts">
export default {
  name: "ModelOwnersList",
};
</script>

<script lang="ts" setup>
import Avatar from "@/shared/components/Avatar/index.vue";
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { LocationQueryRaw } from "vue-router";
import {
  type Model,
  type ModelOwnerVehicle,
  useModelOwners,
} from "@/services/fyApi";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: owners, isLoading } = useModelOwners(() => props.model.slug);

const friendsMore = computed(() =>
  owners.value
    ? owners.value.friends.total - owners.value.friends.items.length
    : 0,
);

const empty = computed(
  () =>
    !!owners.value &&
    !owners.value.vehicles.length &&
    !owners.value.friends.total &&
    !owners.value.fleets.length,
);

const vehicleRoute = (vehicle: ModelOwnerVehicle) => ({
  name: "hangar-vehicle-overview",
  params: { id: vehicle.serial || vehicle.id },
});

// The router writes queries with qs, so a nested `q` filter survives the trip;
// Vue Router's own query type only knows flat values.
const fleetShipsRoute = (slug: string) => ({
  name: "fleet-ships",
  params: { slug },
  query: {
    q: { modelSlugIn: [props.model.slug] },
  } as unknown as LocationQueryRaw,
});
</script>

<template>
  <MetricsCard
    v-if="isLoading || owners"
    class="model-owners"
    :title="t('labels.model.owners.title')"
    :loading="isLoading"
    variant="slim"
    data-test="model-owners"
  >
    <p v-if="empty" class="model-owners__muted model-owners__empty">
      {{ t("labels.model.owners.empty") }}
    </p>

    <div v-else-if="owners" class="model-owners__blocks">
      <section
        v-if="owners.vehicles.length"
        class="model-owners__block"
        data-test="model-owners-vehicles"
      >
        <h3 class="model-owners__heading">
          {{ t("labels.model.owners.yourShips") }}
          <span class="model-owners__count">{{ owners.vehicles.length }}</span>
        </h3>
        <ul class="model-owners__list">
          <li v-for="vehicle in owners.vehicles" :key="vehicle.id">
            <router-link :to="vehicleRoute(vehicle)" class="model-owners__row">
              <i
                v-if="vehicle.flagship"
                class="fa-solid fa-star model-owners__flagship"
                :aria-label="t('labels.vehicle.flagship')"
              />
              <span class="model-owners__name">
                {{ vehicle.name || model.name }}
              </span>
              <span v-if="vehicle.serial" class="model-owners__muted">
                {{ vehicle.serial }}
              </span>
            </router-link>
          </li>
        </ul>
      </section>

      <section
        v-if="owners.friends.total"
        class="model-owners__block"
        data-test="model-owners-friends"
      >
        <h3 class="model-owners__heading">
          {{ t("labels.model.owners.friends") }}
          <span class="model-owners__count">{{ owners.friends.total }}</span>
        </h3>
        <ul class="model-owners__list">
          <li v-for="friend in owners.friends.items" :key="friend.username">
            <router-link
              :to="{
                name: 'hangar-public',
                params: { username: friend.username },
              }"
              class="model-owners__row"
            >
              <Avatar :avatar="friend.avatar" size="small" round />
              <span class="model-owners__name">{{ friend.username }}</span>
              <span v-if="friend.count > 1" class="model-owners__muted">
                ×{{ friend.count }}
              </span>
            </router-link>
          </li>
          <li v-if="friendsMore > 0" class="model-owners__muted">
            {{ t("labels.model.owners.more", { count: friendsMore }) }}
          </li>
        </ul>
      </section>

      <section
        v-if="owners.fleets.length"
        class="model-owners__block"
        data-test="model-owners-fleets"
      >
        <h3 class="model-owners__heading">
          {{ t("labels.model.owners.fleets") }}
        </h3>
        <ul class="model-owners__list">
          <li v-for="fleet in owners.fleets" :key="fleet.id">
            <router-link
              :to="fleetShipsRoute(fleet.slug)"
              class="model-owners__row"
            >
              <img
                v-if="fleet.logo?.smallUrl"
                :src="fleet.logo.smallUrl"
                alt=""
                class="model-owners__logo"
              />
              <span class="model-owners__name">{{ fleet.name }}</span>
              <span class="model-owners__muted">
                {{
                  t("labels.model.owners.fleetShips", { count: fleet.total })
                }}
              </span>
            </router-link>
            <p v-if="fleet.members.length" class="model-owners__members">
              {{ fleet.members.join(", ") }}
              <template v-if="fleet.ownersTotal > fleet.members.length">
                {{
                  t("labels.model.owners.more", {
                    count: fleet.ownersTotal - fleet.members.length,
                  })
                }}
              </template>
            </p>
          </li>
        </ul>
      </section>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
.model-owners {
  &__blocks {
    display: flex;
    flex-direction: column;
    gap: 14px;
  }

  &__heading {
    display: flex;
    align-items: baseline;
    gap: 6px;
    margin: 0 0 6px;
    color: var(--color-text-dim);
    font-size: 11.5px;
    letter-spacing: 0.08em;
    text-transform: uppercase;
  }

  &__count {
    color: var(--color-muted);
    font-variant-numeric: tabular-nums;
  }

  &__list {
    display: flex;
    flex-direction: column;
    gap: 2px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__row {
    display: flex;
    align-items: center;
    gap: 8px;
    min-height: 30px;
    padding: 2px 6px;
    margin: 0 -6px;
    border-radius: 4px;
    color: var(--color-text);
    transition: background-color 150ms ease;

    &:hover,
    &:focus-visible {
      background-color: var(--color-control-hover);
    }
  }

  &__name {
    flex: 1;
    min-width: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__flagship {
    color: var(--color-gold);
    font-size: 0.8em;
  }

  &__logo {
    width: 22px;
    height: 22px;
    object-fit: contain;
  }

  &__members {
    margin: 0 0 4px 30px;
    color: var(--color-text-dim);
    font-size: 12px;
  }

  &__muted {
    color: var(--color-text-dim);
    font-size: 12px;
    font-variant-numeric: tabular-nums;
    white-space: nowrap;
  }

  &__empty {
    margin: 0;
    white-space: normal;
  }
}
</style>
