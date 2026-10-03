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
  totalCount: number;
  locationId: string;
};

const props = defineProps<Props>();

const { t } = useI18n();

const { onlineFor } = useMemberPresence();

// The list arrives online first, so the few shown are who the reader can meet
// now.
const COLLAPSED_LIMIT = 5;

const expanded = ref(false);

const visible = computed(() =>
  expanded.value ? props.people : props.people.slice(0, COLLAPSED_LIMIT),
);

// More than the endpoint sends: a whole fleet can be in one system.
const unlisted = computed(() =>
  Math.max(props.totalCount - props.people.length, 0),
);

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
      <span class="location-people__summary">{{ totalCount }}</span>
    </template>

    <ul class="location-people__list">
      <li
        v-for="person in visible"
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

    <p
      v-if="expanded && unlisted"
      class="location-people__unlisted"
      data-test="location-people-unlisted"
    >
      {{ t("labels.location.peopleUnlisted", { count: unlisted }) }}
    </p>

    <button
      v-if="people.length > COLLAPSED_LIMIT"
      type="button"
      class="location-people__more"
      :aria-expanded="expanded"
      data-test="location-people-more"
      @click="expanded = !expanded"
    >
      {{
        expanded
          ? t("labels.location.showFewer")
          : t("labels.location.showAll", { count: people.length })
      }}
    </button>
  </MetricsCard>
</template>

<style lang="scss" scoped>
@import "index";
</style>
