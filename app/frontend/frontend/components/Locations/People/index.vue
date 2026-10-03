<script lang="ts">
export default {
  name: "LocationPeople",
};
</script>

<script lang="ts" setup>
import MetricsCard from "@/frontend/components/Models/MetricsCard/index.vue";
import LocationName from "@/frontend/components/LocationName/index.vue";
import Avatar from "@/shared/components/Avatar/index.vue";
import { useI18n } from "@/shared/composables/useI18n";
import { useMemberPresence } from "@/frontend/composables/useMemberPresence";
import { type LocationPerson } from "@/services/fyApi";

type Props = {
  people: LocationPerson[];
  locationId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { onlineFor } = useMemberPresence();

// The place is only named where it is one inside the page's: on Lorville's
// page, "Lorville" under every name says nothing.
const placeBelow = (person: LocationPerson) =>
  person.currentLocation && person.currentLocation.id !== props.locationId
    ? person.currentLocation
    : undefined;
</script>

<template>
  <MetricsCard
    class="location-people"
    :title="t('labels.location.people')"
    variant="slim"
  >
    <template #head>
      <span class="location-people__summary">{{ people.length }}</span>
    </template>

    <ul class="location-people__list">
      <li
        v-for="person in people"
        :key="person.id"
        class="location-people__person"
        data-test="location-person"
      >
        <Avatar
          :avatar="person.avatar?.smallUrl"
          size="small"
          :online="onlineFor({ userId: person.id, online: person.online })"
        />
        <span class="location-people__body">
          <span class="location-people__name">{{ person.username }}</span>
          <LocationName
            v-if="placeBelow(person)"
            class="location-people__place"
            :linked="placeBelow(person)"
          />
          <span class="location-people__ties">
            <span
              v-if="person.friend"
              class="location-people__tie"
              data-test="location-person-friend"
            >
              {{ t("labels.location.peopleFriend") }}
            </span>
            <router-link
              v-for="fleet in person.fleets"
              :key="fleet.id"
              :to="{ name: 'fleet', params: { slug: fleet.slug } }"
              class="location-people__tie"
            >
              {{ fleet.name }}
            </router-link>
          </span>
        </span>
      </li>
    </ul>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
