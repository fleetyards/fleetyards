<script lang="ts">
export default {
  name: "VehicleOwnersModal",
};
</script>

<script lang="ts" setup>
import { useRoute } from "vue-router";
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Loader from "@/shared/components/Loader/index.vue";
import Empty from "@/shared/components/Empty/index.vue";
import BtnDropdown from "@/shared/components/base/BtnDropdown/index.vue";
import MemberContactMenu from "@/frontend/components/base/MemberContactMenu/index.vue";
import OwnerRow from "@/frontend/components/Vehicles/OwnersModal/Row/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import type { Owner } from "@/frontend/components/Vehicles/OwnersModal/types";
import {
  type VehiclePublic,
  type FleetVehiclesParams,
  type FleetVehicleQueryLoanerEq,
  useFleetVehicles as useFleetVehiclesQuery,
} from "@/services/fyApi";

type Props = {
  modelSlug: string;
  fleetSlug: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const loanerEq = computed(
  () =>
    (route.query.q as unknown as Record<string, unknown> | undefined)
      ?.loanerEq as FleetVehicleQueryLoanerEq | undefined,
);

const params = computed<FleetVehiclesParams>(() => ({
  grouped: false,
  perPage: "all",
  q: {
    modelSlugIn: [props.modelSlug],
    loanerEq: loanerEq.value,
  },
}));

const { data, status } = useFleetVehiclesQuery(props.fleetSlug, params);

const loading = computed(() => status.value === "pending");

const shipLabel = (vehicle: VehiclePublic) => {
  if (vehicle.name && vehicle.serial) {
    return `${vehicle.name} (${vehicle.serial})`;
  }

  return vehicle.name || vehicle.serial;
};

/*
 * One row per member, not per vehicle: the fleet list already collapses a model
 * to a single panel, so the modal behind it answers "who flies this", and a
 * member with three Cutlasses was previously three rows - or, once deduplicated
 * by username, one row silently dropping the other two ships.
 *
 * Vehicles whose owner is not public carry no identity at all, so they cannot be
 * told apart and all fold into one trailing row with a count.
 */
const owners = computed<Owner[]>(() => {
  const vehicles = (data.value?.items || []) as VehiclePublic[];

  const named = new Map<string, Owner>();
  const anonymous: Owner = { key: "anonymous", count: 0, ships: [] };

  vehicles.forEach((vehicle) => {
    const ship = shipLabel(vehicle);
    const owner = vehicle.username
      ? (named.get(vehicle.username) ?? {
          key: vehicle.username,
          member: {
            username: vehicle.username,
            rsiHandle: vehicle.userRsiHandle,
            discordProfileUrl: vehicle.userDiscordProfileUrl,
            citizenidProfileUrl: vehicle.userCitizenidProfileUrl,
          },
          avatar: vehicle.userAvatar,
          count: 0,
          ships: [],
        })
      : anonymous;

    owner.count += 1;

    if (ship) {
      owner.ships.push(ship);
    }

    if (owner.member?.username) {
      named.set(owner.member.username, owner);
    }
  });

  const sorted = [...named.values()].sort((a, b) =>
    (a.member?.username as string).localeCompare(
      b.member?.username as string,
      undefined,
      {
        sensitivity: "base",
      },
    ),
  );

  return anonymous.count > 0 ? [...sorted, anonymous] : sorted;
});
</script>

<template>
  <Modal :title="t('headlines.fleets.owners')">
    <Loader v-if="loading" :loading="loading" :inline="true" />
    <!-- Actions hidden: they reset the *page's* filters, which is not something
         a modal opened over that page should offer. -->
    <Empty v-else-if="!owners.length" :inline="true" :hide-actions="true" />
    <ul v-else class="owners">
      <li v-for="owner in owners" :key="owner.key">
        <BtnDropdown v-if="owner.member">
          <template #trigger="{ toggle, visible }">
            <OwnerRow
              :owner="owner"
              as="button"
              aria-haspopup="menu"
              :aria-expanded="visible"
              @click="toggle"
            />
          </template>
          <MemberContactMenu :member="owner.member" :hangar="true" />
        </BtnDropdown>
        <OwnerRow v-else :owner="owner" />
      </li>
    </ul>
  </Modal>
</template>

<style lang="scss" scoped>
@import "index";
</style>
