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
import { BtnSizesEnum } from "@/shared/components/base/Btn/types";
import Panel from "@/shared/components/base/Panel/index.vue";
import PanelBody from "@/shared/components/base/Panel/Body/index.vue";
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
const route = useRoute();
const router = useRouter();
const sessionStore = useSessionStore();

const fleetSlug = computed(() => props.fleet.slug);
const contractSlug = computed(() => route.params.contract as string);

const { data: contract, refetch } = useFleetContract(fleetSlug, contractSlug);

const currentUserId = computed(() => sessionStore.currentUser?.id);

const canManage = computed(() =>
  checkAccess(props.resourceAccess, ["fleet:manage", "fleet:contracts:manage"]),
);

const canEdit = computed(() =>
  checkAccess(props.resourceAccess, [
    "fleet:manage",
    "fleet:contracts:manage",
    "fleet:contracts:update",
  ]),
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

const canFulfil = computed(
  () =>
    contract.value?.state === FleetContractStateEnum.IN_PROGRESS &&
    canManage.value,
);

const canPublish = computed(
  () => contract.value?.state === FleetContractStateEnum.DRAFT && canEdit.value,
);

const CANCELLABLE_STATES: FleetContractStateEnum[] = [
  FleetContractStateEnum.DRAFT,
  FleetContractStateEnum.OPEN,
  FleetContractStateEnum.IN_PROGRESS,
];

const canCancel = computed(
  () =>
    canEdit.value &&
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
    <Heading size="hero" hero>
      {{ contract.title }}
    </Heading>

    <div class="contract-detail__meta">
      <ContractStatePill :state="contract.state" />
      <span>{{ t(`labels.fleets.contracts.kind.${contract.kind}`) }}</span>
      <!-- eslint-disable-next-line vue/no-v-html -->
      <span v-html="toUEC(Number(contract.reward))" />
      <span v-if="contract.deadline">{{ l(contract.deadline) }}</span>
    </div>

    <!-- A page's main actions live in the global header, not on the page. -->
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
      <BtnConfirm v-if="canCancel" :size="BtnSizesEnum.MD" @confirm="onCancel">
        <i class="fa-duotone fa-ban" />
        {{ t("actions.fleets.contracts.cancel") }}
      </BtnConfirm>
    </Teleport>

    <p v-if="contract.description" class="contract-detail__description">
      {{ contract.description }}
    </p>

    <Panel>
      <PanelBody>
        <Heading>{{ t("headlines.fleets.contracts.progress") }}</Heading>

        <ContractProgress
          :progress="contract.progress"
          :show-pickup="contract.requiresPickup"
        />

        <!-- Where the goods have to come from and go to. A member reading this
             has to know which inventory to address a transfer to. -->
        <dl class="contract-detail__route">
          <div v-if="contract.source">
            <dt>{{ t("labels.fleets.contracts.from") }}</dt>
            <dd>{{ contract.source.name }}</dd>
          </div>
          <div v-if="contract.destination">
            <dt>{{ t("labels.fleets.contracts.to") }}</dt>
            <dd>{{ contract.destination.name }}</dd>
          </div>
        </dl>

        <p v-if="isContractor" class="contract-detail__hint">
          {{ t("messages.fleets.contracts.deliverHint") }}
        </p>
      </PanelBody>
    </Panel>

    <Panel>
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
  </template>
</template>

<style lang="scss" scoped>
.contract-detail {
  &__meta {
    display: flex;
    align-items: center;
    flex-wrap: wrap;
    gap: 12px;
    margin-bottom: 16px;
  }

  &__description {
    margin-bottom: 24px;
  }

  &__route {
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
    gap: 8px 16px;
    margin: 16px 0 0;

    dt {
      font-size: 0.75em;
      text-transform: uppercase;
      letter-spacing: 0.05em;
      color: $gray-lighter;
      margin: 0;
    }

    dd {
      margin: 0;
    }
  }

  &__hint {
    margin: 16px 0 0;
    font-size: 0.9em;
    color: $gray-lighter;
  }
}
</style>
