<script lang="ts">
export default {
  name: "BlueprintFleetOwners",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useBlueprintFleetOwners } from "@/frontend/composables/useBlueprintFleetOwners";

type Props = {
  blueprintId?: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { fleetsWithOwners } = useBlueprintFleetOwners(() => props.blueprintId);

// Somebody may hold a recipe and appear in the list without a nickname -- the
// fleet has not given them one -- so the fleet's name for them is preferred
// and their username is what everything falls back to.
const nameFor = (owner: { username: string; nickname?: string | null }) =>
  owner.nickname || owner.username;
</script>

<template>
  <!-- Absent rather than empty when no fleet of the reader's has anybody who
       holds this. A panel saying "nobody" on a public catalogue page would be
       a claim about every fleet, and this only ever knows about theirs. -->
  <MetricsCard
    v-if="fleetsWithOwners.length"
    class="blueprint-fleet-owners"
    :title="t('labels.blueprint.fleetOwners')"
    variant="slim"
  >
    <div class="blueprint-fleet-owners__fleets">
      <div
        v-for="fleet in fleetsWithOwners"
        :key="fleet.slug"
        class="blueprint-fleet-owners__fleet"
      >
        <router-link
          class="blueprint-fleet-owners__name"
          :to="{ name: 'fleet-blueprints', params: { slug: fleet.slug } }"
        >
          {{ fleet.name }}
        </router-link>

        <span class="blueprint-fleet-owners__count">
          {{ t("labels.blueprint.ownedByCount", { count: fleet.ownerCount }) }}
        </span>

        <div class="blueprint-fleet-owners__members">
          <router-link
            v-for="owner in fleet.owners"
            :key="owner.userId"
            class="blueprint-fleet-owners__member"
            :to="{
              name: 'hangar-public',
              params: { username: owner.username },
            }"
          >
            {{ nameFor(owner) }}
          </router-link>
        </div>
      </div>
    </div>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
