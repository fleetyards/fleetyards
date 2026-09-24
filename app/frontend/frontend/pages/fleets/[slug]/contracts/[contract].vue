<script lang="ts">
export default {
  name: "FleetContractPage",
};
</script>

<script lang="ts" setup>
import BreadCrumbs from "@/shared/components/BreadCrumbs/index.vue";
import { type Crumb } from "@/shared/components/BreadCrumbs/types";
import Heading from "@/shared/components/base/Heading/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnConfirm from "@/shared/components/base/BtnConfirm/index.vue";
import { BtnSizesEnum, BtnTonesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
import DetailSkeleton from "@/shared/components/DetailSkeleton/index.vue";
import ContractStatePill from "@/frontend/components/Fleets/Contracts/ContractStatePill/index.vue";
import ContractProgress from "@/frontend/components/Fleets/Contracts/ContractProgress/index.vue";
import ContractCrewList from "@/frontend/components/Fleets/Contracts/ContractCrewList/index.vue";
import {
  type Fleet,
  type FleetMember,
  FleetContractStateEnum,
  FleetContractCrewRoleEnum,
  FleetContractCrewStateEnum,
  useFleetContract,
  usePublishFleetContract,
  useClaimFleetContract,
  useReleaseFleetContract,
  useFulfilFleetContract,
  useCancelFleetContract,
  useJoinFleetContractCrew,
  useAcceptFleetContractCrew,
  useDeclineFleetContractCrew,
  useLeaveFleetContractCrew,
} from "@/services/fyApi";
import { useI18n } from "@/shared/composables/useI18n";
import { useContractCover } from "@/frontend/composables/useContractCover";
import { useContractRoute } from "@/frontend/composables/useContractRoute";
import { useSessionStore } from "@/frontend/stores/session";
import { checkAccess } from "@/shared/utils/Access";
import { useRouter } from "vue-router";

type Props = {
  fleet: Fleet;
  membership: FleetMember;
  resourceAccess?: string[];
};

const props = defineProps<Props>();

const { t, toUEC, l } = useI18n();
const { destinationName } = useContractRoute();
const { resolve: resolveCover } = useContractCover();

const cover = computed(() => resolveCover(contract.value, props.fleet));

const percent = computed(() =>
  Math.round((contract.value?.progress?.fraction ?? 0) * 100),
);
const route = useRoute();
const router = useRouter();
const sessionStore = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const contractSlug = computed(() => route.params.contract as string);

const {
  data: contract,
  refetch,
  isLoading,
} = useFleetContract(fleetSlug, contractSlug);

const currentUserId = computed(() => sessionStore.currentUser?.id);

const canManage = computed(() =>
  checkAccess(props.resourceAccess, ["fleet:manage", "fleet:contracts:manage"]),
);

// The privilege on its own. Cancelling and publishing ride on it and reach a
// contract that editing no longer does.
const mayEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:contracts:manage",
    "fleet:contracts:update",
  ]),
);

// Only a draft. Published, it is an offer members have read and may already be
// working to, so the terms stop moving -- the API refuses it either way.
const canEdit = computed(
  () => mayEdit.value && contract.value?.state === FleetContractStateEnum.DRAFT,
);

const crew = computed(() => contract.value?.crew ?? []);

const lead = computed(() =>
  crew.value.find(
    (member) =>
      member.role === FleetContractCrewRoleEnum.LEAD &&
      member.state === FleetContractCrewStateEnum.ACCEPTED,
  ),
);

const isLead = computed(() => lead.value?.user?.id === currentUserId.value);

const myAssignment = computed(() =>
  crew.value.find((member) => member.user?.id === currentUserId.value),
);

const isContractor = computed(
  () => myAssignment.value?.state === FleetContractCrewStateEnum.ACCEPTED,
);

const isInProgress = computed(
  () => contract.value?.state === FleetContractStateEnum.IN_PROGRESS,
);

const isExpired = computed(
  () => contract.value?.state === FleetContractStateEnum.EXPIRED,
);

const canClaim = computed(
  () => contract.value?.state === FleetContractStateEnum.OPEN,
);

const canJoin = computed(
  () =>
    contract.value?.state === FleetContractStateEnum.IN_PROGRESS &&
    !myAssignment.value,
);

const canRelease = computed(
  () =>
    contract.value?.state === FleetContractStateEnum.IN_PROGRESS &&
    (isLead.value || canManage.value),
);

const FULFILLABLE_STATES: FleetContractStateEnum[] = [
  FleetContractStateEnum.IN_PROGRESS,
  FleetContractStateEnum.EXPIRED,
];

const canFulfil = computed(
  () =>
    canManage.value &&
    contract.value !== undefined &&
    FULFILLABLE_STATES.includes(contract.value.state),
);

const canPublish = computed(
  () => contract.value?.state === FleetContractStateEnum.DRAFT && mayEdit.value,
);

const CANCELLABLE_STATES: FleetContractStateEnum[] = [
  FleetContractStateEnum.DRAFT,
  FleetContractStateEnum.OPEN,
  FleetContractStateEnum.IN_PROGRESS,
];

const canCancel = computed(
  () =>
    mayEdit.value &&
    contract.value !== undefined &&
    CANCELLABLE_STATES.includes(contract.value.state),
);

const reload = () => void refetch();

const { mutateAsync: publish } = usePublishFleetContract();
const { mutateAsync: claim } = useClaimFleetContract();
const { mutateAsync: release } = useReleaseFleetContract();
const { mutateAsync: fulfil } = useFulfilFleetContract();
const { mutateAsync: cancel } = useCancelFleetContract();
const { mutateAsync: join } = useJoinFleetContractCrew();
const { mutateAsync: acceptCrew } = useAcceptFleetContractCrew();
const { mutateAsync: declineCrew } = useDeclineFleetContractCrew();
const { mutateAsync: leaveCrew } = useLeaveFleetContractCrew();

const contractParams = computed(() => ({
  fleetSlug: props.fleet.slug,
  slug: contractSlug.value,
}));

const crewParams = (id: string) => ({
  fleetSlug: props.fleet.slug,
  fleetContractSlug: contractSlug.value,
  id,
});

const onPublish = async () => {
  await publish(contractParams.value);
  reload();
};

const onClaim = async () => {
  await claim(contractParams.value);
  reload();
};

const onRelease = async () => {
  await release(contractParams.value);
  reload();
};

const onFulfil = async () => {
  await fulfil(contractParams.value);
  reload();
};

const onCancel = async () => {
  await cancel(contractParams.value);
  reload();
};

const onJoin = async () => {
  await join({
    fleetSlug: props.fleet.slug,
    fleetContractSlug: contractSlug.value,
  });
  reload();
};

const onAcceptCrew = async (id: string) => {
  await acceptCrew(crewParams(id));
  reload();
};

const onDeclineCrew = async (id: string) => {
  await declineCrew(crewParams(id));
  reload();
};

const onRemoveCrew = async (id: string) => {
  await leaveCrew(crewParams(id));
  reload();
};

const goToEdit = () => {
  void router.push({
    name: "fleet-contract-edit",
    params: { slug: props.fleet.slug, contract: contractSlug.value },
  });
};

const crumbs = computed<Crumb[]>(() => [
  {
    to: { name: "fleet", params: { slug: props.fleet.slug } },
    label: props.fleet.name,
  },
  {
    to: { name: "fleet-contracts", params: { slug: props.fleet.slug } },
    label: t("headlines.fleets.contracts.index"),
  },
]);
</script>

<template>
  <BreadCrumbs :crumbs="crumbs" />

  <template v-if="contract">
    <!-- The cover carries the title, the way a contract card's does. -->
    <div class="contract-hero">
      <img :src="cover" alt="" class="contract-hero__cover" />
      <!-- The seam into the page below; the head carries its own band. -->
      <div class="contract-hero__seam" />

      <div class="contract-hero__body">
        <div class="contract-hero__meta">
          <span class="contract-hero__kind">
            {{ t(`labels.fleets.contracts.kind.${contract.kind}`) }}
          </span>
          <span class="contract-hero__dot" />
          <ContractStatePill :state="contract.state" />
        </div>

        <Heading size="hero" hero shadow class="contract-hero__title">
          {{ contract.title }}
        </Heading>

        <p v-if="contract.createdBy" class="contract-hero__byline">
          {{ t("labels.fleets.contracts.postedBy") }}
          <strong>{{ contract.createdBy.username }}</strong>
          <template v-if="lead?.user">
            ·
            {{ t("labels.fleets.contracts.claimedBy") }}
            <strong>{{ lead.user.username }}</strong>
          </template>
        </p>
      </div>
    </div>

    <!-- The figures overlap the hero's seam, so the page opens on what it pays
         and how far it has got rather than on a photograph. -->
    <div class="metrics-card__hero contract-detail__figures">
      <div class="metrics-card__tile metrics-card__tile--primary">
        <div class="metrics-card__tile__label">
          {{ t("labels.fleets.contracts.reward") }}
        </div>
        <!-- eslint-disable-next-line vue/no-v-html -->
        <div
          class="metrics-card__tile__value"
          v-html="toUEC(Number(contract.reward))"
        />
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.fleets.contracts.delivered") }}
        </div>
        <div class="metrics-card__tile__value">{{ percent }} %</div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("labels.fleets.contracts.deadline") }}
        </div>
        <div class="metrics-card__tile__value">
          {{ contract.deadline ? l(contract.deadline) : "—" }}
        </div>
      </div>
      <div class="metrics-card__tile">
        <div class="metrics-card__tile__label">
          {{ t("headlines.fleets.contracts.crew") }}
        </div>
        <div class="metrics-card__tile__value">{{ crew.length }}</div>
      </div>
    </div>

    <Teleport to="#header-right">
      <Btn
        v-if="canPublish"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.publish')"
        data-test="publish-contract"
        mobile-icon-only
        @click="onPublish"
      >
        <i class="fa-duotone fa-paper-plane" />
        {{ t("actions.fleets.contracts.publish") }}
      </Btn>
      <Btn
        v-if="canClaim"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.claim')"
        data-test="claim-contract"
        mobile-icon-only
        @click="onClaim"
      >
        <i class="fa-duotone fa-hand" />
        {{ t("actions.fleets.contracts.claim") }}
      </Btn>
      <Btn
        v-if="canJoin"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.join')"
        data-test="join-contract"
        mobile-icon-only
        @click="onJoin"
      >
        <i class="fa-duotone fa-user-plus" />
        {{ t("actions.fleets.contracts.join") }}
      </Btn>
      <Btn
        v-if="canRelease"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.release')"
        mobile-icon-only
        @click="onRelease"
      >
        <i class="fa-duotone fa-hand-wave" />
        {{ t("actions.fleets.contracts.release") }}
      </Btn>
      <Btn
        v-if="canFulfil"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.fulfil')"
        data-test="fulfil-contract"
        mobile-icon-only
        @click="onFulfil"
      >
        <i class="fa-duotone fa-circle-check" />
        {{ t("actions.fleets.contracts.fulfil") }}
      </Btn>
      <Btn
        v-if="canEdit"
        :size="BtnSizesEnum.MD"
        :aria-label="t('actions.fleets.contracts.edit')"
        mobile-icon-only
        @click="goToEdit"
      >
        <i class="fa-duotone fa-pen" />
        {{ t("actions.fleets.contracts.edit") }}
      </Btn>
      <BtnConfirm
        v-if="canCancel"
        :size="BtnSizesEnum.MD"
        :tone="BtnTonesEnum.DANGER"
        @confirm="onCancel"
      >
        <i class="fa-duotone fa-ban" />
        {{ t("actions.fleets.contracts.cancel") }}
      </BtnConfirm>
    </Teleport>

    <p v-if="contract.description" class="contract-detail__description">
      {{ contract.description }}
    </p>

    <!-- A haul has two ends, so it reads as one leg rather than two facts. -->
    <Panel v-if="contract.source || contract.destination">
      <PanelBody>
        <div class="contract-route">
          <div v-if="contract.source" class="contract-route__end">
            <div class="contract-route__label">
              {{ t("labels.fleets.contracts.from") }}
            </div>
            <div class="contract-route__place">{{ contract.source.name }}</div>
            <div v-if="contract.source.location" class="contract-route__where">
              {{ contract.source.location }}
            </div>
          </div>

          <div v-if="contract.source" class="contract-route__leg">
            <span class="contract-route__rule" />
            <i class="fa-duotone fa-arrow-right" />
            <span class="contract-route__rule" />
          </div>

          <div
            v-if="contract.destination"
            class="contract-route__end contract-route__end--to"
          >
            <div class="contract-route__label">
              {{ t("labels.fleets.contracts.to") }}
            </div>
            <div class="contract-route__place">
              {{ destinationName(contract) }}
            </div>
            <div
              v-if="contract.destination.location"
              class="contract-route__where"
            >
              {{ contract.destination.location }}
            </div>
          </div>
        </div>
      </PanelBody>
    </Panel>

    <div class="contract-detail__columns">
      <Panel>
        <PanelBody>
          <Heading>{{ t("headlines.fleets.contracts.progress") }}</Heading>

          <ContractProgress
            :progress="contract.progress"
            :show-pickup="contract.requiresPickup"
          />

          <p
            v-if="isContractor && isInProgress"
            class="contract-detail__hint"
            data-test="contract-deliver-hint"
          >
            <i class="fa-duotone fa-circle-info" />
            {{ t("messages.fleets.contracts.deliverHint") }}
          </p>
          <p
            v-else-if="isContractor && isExpired"
            class="contract-detail__hint"
            data-test="contract-expired-hint"
          >
            <i class="fa-duotone fa-circle-info" />
            {{ t("messages.fleets.contracts.expiredHint") }}
          </p>
        </PanelBody>
      </Panel>

      <Panel v-if="crew.length">
        <PanelBody>
          <Heading>{{ t("headlines.fleets.contracts.crew") }}</Heading>

          <ContractCrewList
            :crew="crew"
            :can-answer="isLead || canManage"
            :current-user-id="currentUserId"
            @accept="onAcceptCrew"
            @decline="onDeclineCrew"
            @remove="onRemoveCrew"
          />
        </PanelBody>
      </Panel>
    </div>
  </template>

  <!-- The four figures the page opens on - reward, delivered, deadline, crew -
       over the hero's seam, then the route and progress panels. All four are
       unconditional, so reserving three let the last tile shift the strip as it
       arrived. Same arrangement as the real page, so nothing moves once the
       contract lands. -->
  <DetailSkeleton v-else-if="isLoading" :figures="4" :panels="2" />
</template>

<style lang="scss" scoped>
@import "@/shared/components/metricsCard";

/*
 * Inside App.vue's page container, not bleeding past it. A negative margin has
 * to know `.main`'s padding-inline to cancel it, and guessing wrong widens the
 * page: at -20px against its actual 15px the document scrolled sideways by
 * 10px. The container owns the gutter -- see the panels either side, which
 * share this edge.
 */
.contract-hero {
  position: relative;
  height: 260px;
  overflow: hidden;
  border-radius: var(--radius-surface, 16px) var(--radius-surface, 16px) 0 0;

  &__cover {
    width: 100%;
    height: 100%;
    object-fit: cover;
    display: block;
  }

  /*
   * The panel heading's treatment, which is how every other card over a
   * photograph does this: a band at the top that the text sits in, not a
   * darkening of the whole image. Held through the middle rather than fading
   * at once, so a byline under the title has something under it too.
   */
  &__body {
    position: absolute;
    top: 0;
    right: 24px;
    left: 24px;
    padding: 20px 0 32px;

    &::before {
      content: "";
      position: absolute;
      top: 0;
      right: -24px;
      bottom: 0;
      left: -24px;
      border-radius: var(--radius-surface, 16px) var(--radius-surface, 16px) 0 0;
      background: linear-gradient(
        to bottom,
        rgb(0 0 0 / 0.8),
        rgb(0 0 0 / 0.55) 55%,
        transparent
      );
    }

    > * {
      position: relative;
    }
  }

  // Down to the page's own black, so the figures below sit on a seam rather
  // than on a hard edge. Only the last stretch, which leaves the photograph
  // itself readable.
  &__seam {
    position: absolute;
    right: 0;
    bottom: 0;
    left: 0;
    height: 45%;
    background: linear-gradient(180deg, rgba(#000, 0) 0%, $background 100%);
  }

  &__meta {
    display: flex;
    align-items: center;
    gap: 10px;
    margin-bottom: 12px;
  }

  &__kind {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: $gray-light;
  }

  &__dot {
    width: 3px;
    height: 3px;
    border-radius: 50%;
    background: $gray;
  }

  &__title {
    margin: 0;
    max-width: 24ch;
    text-wrap: pretty;
  }

  &__byline {
    margin: 10px 0 0;
    font-size: 0.85em;
    color: $gray-lighter;
  }
}

.contract-detail {
  &__figures {
    position: relative;
    z-index: 2;
    margin-top: -18px;
  }

  &__description {
    margin-bottom: 24px;
  }

  &__columns {
    display: grid;
    grid-template-columns: minmax(0, 1.65fr) minmax(0, 1fr);
    gap: 24px;
    align-items: start;

    // The crew would be a column of initials at this width; it goes underneath.
    @media (max-width: $desktop-breakpoint) {
      grid-template-columns: minmax(0, 1fr);
    }
  }

  &__hint {
    display: flex;
    align-items: baseline;
    gap: 8px;
    margin: 18px 0 0;
    padding-top: 16px;
    border-top: 1px solid rgba($gray-light, 0.16);
    font-size: 0.85em;
    color: $gray-light;
  }
}

.contract-route {
  display: flex;
  align-items: center;
  gap: 18px;

  &__end {
    flex: 1 1 0;
    min-width: 0;

    &--to {
      text-align: right;
    }
  }

  &__label {
    font-family: "Orbitron", tahoma, sans-serif;
    font-size: 10px;
    letter-spacing: 0.16em;
    text-transform: uppercase;
    color: $gray-light;
    margin-bottom: 6px;
  }

  &__place {
    color: #eee;
  }

  &__where {
    margin-top: 4px;
    font-size: 0.8em;
    color: $gray-light;
  }

  &__leg {
    flex: none;
    display: flex;
    align-items: center;
    gap: 10px;
    color: $gray-light;
  }

  &__rule {
    width: 46px;
    height: 1px;
    background: rgba($gray-light, 0.4);
  }

  @media (max-width: $tablet-breakpoint) {
    flex-direction: column;
    align-items: stretch;
    gap: 12px;

    &__end--to {
      text-align: left;
    }

    &__leg {
      justify-content: center;
    }
  }
}
</style>
