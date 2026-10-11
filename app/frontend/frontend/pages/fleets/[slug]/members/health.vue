<script lang="ts">
export default {
  name: "FleetMembersHealthPage",
};
</script>

<script lang="ts" setup>
import { keepPreviousData } from "@tanstack/vue-query";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Alert from "@/shared/components/base/Alert/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import AsyncData from "@/shared/components/AsyncData.vue";
import FleetMembersList from "@/frontend/components/Fleets/MembersList/index.vue";
import { subDays, formatISO } from "date-fns";
import {
  useFleetMemberHealth,
  type Fleet,
  type FleetMember,
  type FleetMemberHealthParams,
} from "@/services/fyApi";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
};

const props = defineProps<Props>();

const { t } = useI18n();

const route = useRoute();

const comlink = useComlink();

const DAY_STEPS = [14, 30, 60, 90, 180];

const DEFAULT_DAYS = 30;

const days = computed(() => {
  const value = Number(route.query.days);

  return DAY_STEPS.includes(value) ? value : DEFAULT_DAYS;
});

const params = computed<FleetMemberHealthParams>(() => ({
  inactiveDays: days.value,
}));

const { data: health, ...asyncStatus } = useFleetMemberHealth(
  props.fleet.slug,
  params,
  // A new threshold keeps the old lists on screen until the new ones arrive,
  // instead of dropping the whole page to a spinner.
  { query: { placeholderData: keepPreviousData } },
);

const daysLink = (value: number) => ({
  query: { ...route.query, days: value === DEFAULT_DAYS ? undefined : value },
});

// The full lists live on the members page, filtered the same way.
const inactiveListLink = computed(() => ({
  name: "fleet-members-index",
  params: { slug: props.fleet.slug },
  query: {
    inactiveSince: formatISO(subDays(new Date(), days.value), {
      representation: "date",
    }),
    s: "lastActiveAt asc",
  },
}));

const unverifiedListLink = computed(() => ({
  name: "fleet-members-index",
  params: { slug: props.fleet.slug },
  query: { verifiedEq: "false" },
}));

const canUpdateRoles = computed(
  () => props.membership?.capabilities?.updateRoles ?? false,
);

const onMemberUpdate = () => {
  void asyncStatus.refetch();
};

let offMemberUpdate: (() => void) | undefined;

onMounted(() => {
  offMemberUpdate = comlink.on("fleet-member-update", onMemberUpdate);
});

onUnmounted(() => {
  offMemberUpdate?.();
});

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-members-index", params: { slug: props.fleet.slug } },
    label: t("nav.fleets.members.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />
  <Heading>
    {{ t("headlines.fleets.members.health") }}
  </Heading>

  <AsyncData :async-status="asyncStatus">
    <template #resolved>
      <template v-if="health">
        <section class="health-section" data-test="health-inactive">
          <Heading level="h2" size="xl" mb>
            {{
              t("labels.fleet.members.health.inactive.title", {
                count: health.inactiveMembers.totalCount,
              })
            }}
          </Heading>
          <div class="health-section__toolbar">
            <span class="text-muted">
              {{ t("labels.fleet.members.health.inactive.threshold") }}
            </span>
            <BtnGroup segmented>
              <Btn
                v-for="step in DAY_STEPS"
                :key="step"
                :to="daysLink(step)"
                :active="days === step"
                :data-test="`health-days-${step}`"
              >
                {{
                  t("labels.fleet.members.health.inactive.days", {
                    count: step,
                  })
                }}
              </Btn>
            </BtnGroup>
          </div>
          <template v-if="health.inactiveMembers.totalCount">
            <FleetMembersList
              :members="health.inactiveMembers.items"
              :capabilities="membership?.capabilities"
              :sortable-columns="false"
            />
            <Btn
              v-if="
                health.inactiveMembers.totalCount >
                health.inactiveMembers.items.length
              "
              :to="inactiveListLink"
              data-test="health-inactive-all"
            >
              {{
                t("actions.fleet.members.health.showAll", {
                  count: health.inactiveMembers.totalCount,
                })
              }}
            </Btn>
          </template>
          <Alert v-else variant="success" size="compact">
            {{ t("texts.fleet.members.health.inactive.none", { count: days }) }}
          </Alert>
        </section>

        <section
          v-if="health.unverifiedMembers"
          class="health-section"
          data-test="health-unverified"
        >
          <Heading level="h2" size="xl" mb>
            {{
              t("labels.fleet.members.health.unverified.title", {
                count: health.unverifiedMembers.totalCount,
              })
            }}
          </Heading>
          <Alert
            v-if="!health.fleetRsiVerified"
            variant="warning"
            size="compact"
            data-test="health-fleet-unverified"
          >
            {{ t("texts.fleet.members.health.unverified.fleetNotVerified") }}
          </Alert>
          <template v-if="health.unverifiedMembers.totalCount">
            <FleetMembersList
              :members="health.unverifiedMembers.items"
              :capabilities="membership?.capabilities"
              :sortable-columns="false"
            />
            <Btn
              v-if="
                health.unverifiedMembers.totalCount >
                health.unverifiedMembers.items.length
              "
              :to="unverifiedListLink"
              data-test="health-unverified-all"
            >
              {{
                t("actions.fleet.members.health.showAll", {
                  count: health.unverifiedMembers.totalCount,
                })
              }}
            </Btn>
          </template>
          <Alert v-else variant="success" size="compact">
            {{ t("texts.fleet.members.health.unverified.none") }}
          </Alert>
        </section>

        <section
          v-if="health.emptyRoles"
          class="health-section"
          data-test="health-empty-roles"
        >
          <Heading level="h2" size="xl" mb>
            {{
              t("labels.fleet.members.health.emptyRoles.title", {
                count: health.emptyRoles.length,
              })
            }}
          </Heading>
          <template v-if="health.emptyRoles.length">
            <ul class="health-roles">
              <li
                v-for="role in health.emptyRoles"
                :key="role.id"
                :data-test="`health-empty-role-${role.slug}`"
              >
                {{ role.name }}
              </li>
            </ul>
            <Btn
              :to="{
                name: 'fleet-settings-roles',
                params: { slug: fleet.slug },
              }"
              data-test="health-roles-settings"
            >
              <i class="fa-duotone fa-user-shield" />
              {{
                canUpdateRoles
                  ? t("actions.fleet.members.health.editRoles")
                  : t("actions.fleet.members.health.viewRoles")
              }}
            </Btn>
          </template>
          <Alert v-else variant="success" size="compact">
            {{ t("texts.fleet.members.health.emptyRoles.none") }}
          </Alert>
        </section>
      </template>
    </template>
  </AsyncData>
</template>

<style lang="scss" scoped>
.health-section + .health-section {
  margin-top: 40px;
}

.health-section__toolbar {
  display: flex;
  flex-wrap: wrap;
  align-items: center;
  gap: 10px;
  margin-bottom: 15px;
}

.health-roles {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 20px;
  margin: 0 0 15px;
  padding-left: 20px;
}
</style>
