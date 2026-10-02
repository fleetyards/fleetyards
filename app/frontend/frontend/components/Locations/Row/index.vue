<script lang="ts">
export default {
  name: "LocationRow",
};
</script>

<script lang="ts" setup>
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  type RowListItemBadge,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Location } from "@/services/fyApi";

type Props = {
  location: Location;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

// Into the list, wherever the row is: a place's page lists what sits inside
// it with these rows too, and filtering that page's own route would only
// change the address.
const filterLink = (key: string, value: string | string[]) => ({
  name: "locations-places",
  query: {
    ...(route.name === "locations-places" ? route.query : {}),
    page: undefined,
    [key]: value,
  },
});

const tags = computed<RowListItemTag[]>(() => [
  {
    key: props.location.kind,
    label: t(`labels.location.kinds.${props.location.kind}`),
    to: filterLink("kindIn", [props.location.kind]),
  },
]);

// Said on the row: 1,107 of the 1,847 places are hidden on the in-game map,
// and a reader looking for one there needs to know before they click.
const badges = computed<RowListItemBadge[]>(() => {
  if (props.location.alwaysShown) {
    return [{ key: "always-shown", value: t("labels.location.alwaysShown") }];
  }

  if (!props.location.shownOnStarmap) {
    return [
      {
        key: "hidden",
        value: t("labels.location.hiddenOnStarmap"),
        quiet: true,
      },
    ];
  }

  return [];
});
</script>

<template>
  <RowListItem
    class="location-row"
    :to="{ name: 'location', params: { slug: location.slug } }"
    :tags="tags"
    :badges="badges"
  >
    <template #name>{{ location.name }}</template>

    <!-- The parent, which is what tells apart the places that share a name:
         two Outpost 54s sit on Aberdeen. -->
    <template #sub>
      <router-link
        v-if="location.parent"
        :to="{ name: 'location', params: { slug: location.parent.slug } }"
      >
        {{ location.parent.name }}
      </router-link>
      <span v-if="location.parent?.parentName">
        {{ location.parent.parentName }}
      </span>
    </template>
  </RowListItem>
</template>
