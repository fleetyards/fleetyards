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
import { useVehicleRoute } from "@/frontend/composables/useVehicleRoute";

type Props = {
  model: Model;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { data: owners, isLoading } = useModelOwners(() => props.model.slug);

const STACK_SIZE = 6;
const NAMED_FRIENDS = 3;

const friendsStack = computed(
  () => owners.value?.friends.items.slice(0, STACK_SIZE) ?? [],
);

const friendsStackMore = computed(() =>
  owners.value ? owners.value.friends.total - friendsStack.value.length : 0,
);

const namedFriends = computed(
  () => owners.value?.friends.items.slice(0, NAMED_FRIENDS) ?? [],
);

const friendsMore = computed(() =>
  owners.value ? owners.value.friends.total - namedFriends.value.length : 0,
);

const vehicleImage = (vehicle: ModelOwnerVehicle) =>
  (vehicle.image || props.model.media.storeImage)?.smallUrl;

const empty = computed(
  () =>
    !!owners.value &&
    !owners.value.vehicles.length &&
    !owners.value.friends.total &&
    !owners.value.fleets.length,
);

const toVehicle = useVehicleRoute();

const vehicleRoute = (vehicle: ModelOwnerVehicle) =>
  toVehicle("hangar-vehicle-overview", vehicle);

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
        </h3>
        <ul class="model-owners__list">
          <li v-for="vehicle in owners.vehicles" :key="vehicle.id">
            <router-link :to="vehicleRoute(vehicle)" class="model-owners__ship">
              <img
                v-if="vehicleImage(vehicle)"
                :src="vehicleImage(vehicle)"
                alt=""
                class="model-owners__thumb"
              />
              <span v-else class="model-owners__thumb" />
              <span class="model-owners__ship-text">
                <span class="model-owners__name">
                  <i
                    v-if="vehicle.flagship"
                    class="fa fa-certificate model-owners__flagship"
                    :aria-label="t('labels.vehicle.flagship')"
                  />
                  {{ vehicle.name || model.name }}
                </span>
                <span v-if="vehicle.serial" class="model-owners__muted">
                  {{ vehicle.serial }}
                </span>
              </span>
              <i class="fa-light fa-chevron-right model-owners__chevron" />
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
        <div class="model-owners__stack">
          <router-link
            v-for="friend in friendsStack"
            :key="friend.username"
            v-tooltip="friend.username"
            :to="{
              name: 'hangar-public',
              params: { username: friend.username },
            }"
            :aria-label="friend.username"
            class="model-owners__face"
          >
            <Avatar :avatar="friend.avatar?.smallUrl" size="small" round />
          </router-link>
          <span v-if="friendsStackMore > 0" class="model-owners__muted">
            +{{ friendsStackMore }}
          </span>
        </div>
        <p class="model-owners__names">
          <template
            v-for="(friend, index) in namedFriends"
            :key="friend.username"
          >
            <router-link
              :to="{
                name: 'hangar-public',
                params: { username: friend.username },
              }"
              class="model-owners__friend"
              >{{ friend.username }}</router-link
            ><span v-if="friend.count > 1" class="model-owners__muted">
              ×{{ friend.count }}</span
            ><template v-if="index < namedFriends.length - 1">, </template>
          </template>
          <span v-if="friendsMore > 0" class="model-owners__muted">
            {{ t("labels.model.owners.more", { count: friendsMore }) }}
          </span>
        </p>
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
              class="model-owners__fleet"
            >
              <img
                v-if="fleet.logo?.smallUrl"
                :src="fleet.logo.smallUrl"
                alt=""
                class="model-owners__logo"
              />
              <span v-else class="model-owners__logo model-owners__logo--empty">
                <i class="fa-duotone fa-people-group" />
              </span>
              <span class="model-owners__fleet-text">
                <span class="model-owners__fleet-title">
                  <span class="model-owners__name">{{ fleet.name }}</span>
                  <span
                    class="model-owners__total"
                    :aria-label="
                      t('labels.model.owners.fleetShips', {
                        count: fleet.total,
                      })
                    "
                  >
                    {{ fleet.total }}
                  </span>
                </span>
                <span v-if="fleet.members.length" class="model-owners__muted">
                  {{ fleet.members.join(", ") }}
                  <template v-if="fleet.ownersTotal > fleet.members.length">
                    {{
                      t("labels.model.owners.more", {
                        count: fleet.ownersTotal - fleet.members.length,
                      })
                    }}
                  </template>
                </span>
              </span>
            </router-link>
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
  }

  &__block {
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding: 12px 0;

    & + & {
      border-top: 1px solid var(--color-edge-faint);
    }

    &:last-child {
      padding-bottom: 0;
    }
  }

  &__heading {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 6px;
    margin: 0;
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
    gap: 6px;
    margin: 0;
    padding: 0;
    list-style: none;
  }

  &__ship {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 6px;
    border: 1px solid var(--color-edge-faint);
    border-radius: 8px;
    background-color: var(--color-field);
    color: var(--color-text);
    transition:
      background-color 150ms ease,
      border-color 150ms ease;

    &:hover,
    &:focus-visible {
      border-color: var(--color-edge-soft);
      background-color: var(--color-control-hover);
    }
  }

  &__thumb {
    flex-shrink: 0;
    width: 64px;
    height: 40px;
    border-radius: 5px;
    background-color: var(--color-gray-darker);
    object-fit: cover;
  }

  &__ship-text,
  &__fleet-text {
    display: flex;
    flex: 1;
    flex-direction: column;
    min-width: 0;
  }

  &__name {
    min-width: 0;
    overflow: hidden;
    color: var(--color-text);
    font-weight: 600;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  &__chevron {
    color: var(--color-muted);
    font-size: 12px;
  }

  &__flagship {
    margin-right: 4px;
    color: var(--color-gold);
    font-size: 0.8em;
  }

  &__stack {
    display: flex;
    align-items: center;
    padding-left: 8px;
  }

  &__face {
    margin-left: -8px;
    border-radius: 50%;
    box-shadow: 0 0 0 2px var(--color-gray-darker);
    transition: transform 150ms ease;

    &:hover,
    &:focus-visible {
      z-index: 1;
      transform: translateY(-2px);
    }

    :deep(.avatar) {
      width: 34px;
      min-width: 34px;
      height: 34px;
    }

    & + .model-owners__muted {
      margin-left: 10px;
    }
  }

  &__names {
    margin: 0;
    font-size: 13px;
    line-height: 1.5;
  }

  &__friend {
    color: var(--color-text);
    font-weight: 600;

    &:hover,
    &:focus-visible {
      color: var(--color-lifted);
    }
  }

  &__fleet {
    display: flex;
    align-items: center;
    gap: 12px;
    padding: 6px;
    margin: 0 -6px;
    border-radius: 6px;
    color: var(--color-text);
    transition: background-color 150ms ease;

    &:hover,
    &:focus-visible {
      background-color: var(--color-control-hover);
    }
  }

  &__fleet-title {
    display: flex;
    align-items: baseline;
    justify-content: space-between;
    gap: 8px;
  }

  &__total {
    font-family: Orbitron, sans-serif;
    font-size: 13px;
    font-variant-numeric: tabular-nums;
  }

  &__logo {
    flex-shrink: 0;
    width: 36px;
    height: 36px;
    object-fit: contain;

    &--empty {
      display: flex;
      align-items: center;
      justify-content: center;
      color: var(--color-muted);
      font-size: 18px;
    }
  }

  &__muted {
    color: var(--color-text-dim);
    font-size: 12px;
    font-variant-numeric: tabular-nums;
  }

  &__empty {
    margin: 0;
    padding-top: 12px;
  }
}
</style>
