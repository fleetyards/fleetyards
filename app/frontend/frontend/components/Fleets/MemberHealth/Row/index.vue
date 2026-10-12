<script lang="ts">
export default {
  name: "FleetMemberHealthRow",
};
</script>

<script lang="ts" setup>
import type { RouteLocationRaw } from "vue-router";
import Avatar from "@/shared/components/Avatar/index.vue";
import MemberPopover from "@/frontend/components/Fleets/MemberPopover/index.vue";

type Props = {
  title: string;
  to?: RouteLocationRaw;
  avatar?: string;
  // Text in the avatar's place, for a row that is not a person.
  mark?: string;
  subline?: string;
  chip?: string;
  // A leader's role is marked: their absence leaves a gap a member's does not.
  chipLoud?: boolean;
  fact?: string;
  factSub?: string;
  factLoud?: boolean;
  // A member's name opens their card, for everything the row leaves out.
  member?: { fleetSlug: string; username: string; fleetSid?: string };
};

const props = withDefaults(defineProps<Props>(), {
  to: undefined,
  avatar: undefined,
  mark: undefined,
  subline: undefined,
  chip: undefined,
  chipLoud: false,
  fact: undefined,
  factSub: undefined,
  factLoud: false,
  member: undefined,
});

// The fact the check is about leads; the rest follows it on the same line.
const details = computed(() =>
  [props.factSub, props.subline].filter(Boolean).join(" · "),
);
</script>

<template>
  <li class="health-row">
    <span v-if="mark" class="health-row__mark" aria-hidden="true">
      {{ mark }}
    </span>
    <Avatar v-else :avatar="avatar" size="small" />
    <span class="health-row__main">
      <span class="health-row__head">
        <MemberPopover v-if="member && to" v-bind="member">
          <router-link :to="to" class="health-row__title">
            {{ title }}
          </router-link>
        </MemberPopover>
        <router-link v-else-if="to" :to="to" class="health-row__title">
          {{ title }}
        </router-link>
        <span v-else class="health-row__title">{{ title }}</span>
        <span
          v-if="chip"
          class="health-row__chip"
          :class="{ 'health-row__chip--loud': chipLoud }"
        >
          {{ chip }}
        </span>
      </span>
      <span v-if="fact || details" class="health-row__meta">
        <span
          v-if="fact"
          class="health-row__fact"
          :class="{ 'health-row__fact--loud': factLoud }"
        >
          {{ fact }}
        </span>
        <span v-if="fact && details" aria-hidden="true"> · </span>
        <span v-if="details">{{ details }}</span>
      </span>
    </span>
    <span v-if="$slots.actions" class="health-row__actions">
      <slot name="actions" />
    </span>
  </li>
</template>

<style lang="scss" scoped>
// One line per member however narrow the column: the text gives way and
// truncates, the actions never wrap under it.
.health-row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 20px;
  border-bottom: 1px solid rgb(122 130 136 / 0.15);

  &:last-child {
    border-bottom: 0;
  }
}

.health-row__mark {
  display: flex;
  flex: 0 0 auto;
  align-items: center;
  justify-content: center;
  width: 32px;
  height: 32px;
  border-radius: 3px;
  background: rgb(66 139 202 / 0.15);
  color: var(--color-primary-tint, #92bce0);
  font-size: 12px;
  font-weight: 700;
}

.health-row__main {
  display: flex;
  flex: 1 1 auto;
  flex-direction: column;
  gap: 2px;
  min-width: 0;
}

.health-row__head {
  display: flex;
  align-items: center;
  gap: 8px;
  min-width: 0;
}

.health-row__title {
  overflow: hidden;
  color: var(--color-lifted, #eee);
  font-weight: 600;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.health-row__chip {
  flex: 0 0 auto;
  padding: 0 6px;
  border: 1px solid rgb(122 130 136 / 0.4);
  border-radius: 3px;
  font-size: 12px;
}

.health-row__chip--loud {
  border-color: var(--color-warning, #fa6800);
  color: var(--color-warning, #fa6800);
  font-weight: 700;
}

.health-row__meta {
  overflow: hidden;
  color: var(--color-text-dim, #959595);
  font-size: 12px;
  text-overflow: ellipsis;
  white-space: nowrap;
}

.health-row__fact {
  color: var(--color-text, #c8c8c8);
}

.health-row__fact--loud {
  color: var(--color-warning, #fa6800);
}

.health-row__actions {
  display: flex;
  flex: 0 0 auto;
  gap: 6px;
}
</style>
