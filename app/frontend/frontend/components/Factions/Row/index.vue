<script lang="ts">
export default {
  name: "FactionRow",
};
</script>

<script lang="ts" setup>
import RowListItem from "@/shared/components/RowListItem/index.vue";
import {
  RowListItemTonesEnum,
  type RowListItemBadge,
  type RowListItemTag,
} from "@/shared/components/RowListItem/types";
import { useI18n } from "@/shared/composables/useI18n";
import { type Faction } from "@/services/fyApi";

type Props = {
  faction: Faction;
};

const props = defineProps<Props>();

const { t, toNumber } = useI18n();

const TONES: Record<string, RowListItemTonesEnum> = {
  lawful: RowListItemTonesEnum.PRIMARY,
  outlaw: RowListItemTonesEnum.DANGER,
};

const tags = computed<RowListItemTag[]>(() => {
  const { alignment } = props.faction;

  if (!alignment) return [];

  return [
    {
      key: alignment,
      label: t(`labels.gameMission.alignments.${alignment}`),
      tone: TONES[alignment],
    },
  ];
});

const badges = computed<RowListItemBadge[]>(() => [
  {
    key: "missions",
    label: t("labels.faction.missions"),
    value: String(toNumber(props.faction.missionCount)),
  },
]);

const logo = computed(
  () => props.faction.logo?.smallUrl || props.faction.logo?.url,
);

const sub = computed(() =>
  [props.faction.focus, props.faction.area].filter(Boolean).join(" · "),
);
</script>

<template>
  <RowListItem
    :to="{ name: 'faction', params: { slug: faction.slug } }"
    :tags="tags"
    :badges="badges"
  >
    <template #leading>
      <span class="faction-row__logo">
        <img v-if="logo" :src="logo" alt="" />
      </span>
    </template>

    <template #name>{{ faction.name }}</template>

    <template #sub>{{ sub }}</template>
  </RowListItem>
</template>

<style lang="scss" scoped>
.faction-row__logo {
  flex: none;
  width: 32px;
  height: 32px;

  img {
    width: 100%;
    height: 100%;
    object-fit: contain;
  }
}
</style>
