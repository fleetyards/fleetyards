<script lang="ts">
export default {
  name: "HangarPlannerRouteModal",
};
</script>

<script lang="ts" setup>
import Modal from "@/shared/components/AppModal/Inner/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import BtnGroup from "@/shared/components/base/BtnGroup/index.vue";
import {
  BtnSizesEnum,
  BtnTonesEnum,
  BtnTypesEnum,
  BtnVariantsEnum,
} from "@/shared/components/base/Btn/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import { InputTypesEnum } from "@/shared/components/base/FormInput/types";
import Alert from "@/shared/components/base/Alert/index.vue";
import FormCheckbox from "@/shared/components/base/FormCheckbox/index.vue";
import Chip from "@/shared/components/base/Chip/index.vue";
import { ChipStatesEnum } from "@/shared/components/base/Chip/types";
import ModelSelect from "@/frontend/components/Hangar/Planner/ModelSelect/index.vue";
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import RouteChain from "@/frontend/components/Hangar/Planner/RouteChain/index.vue";
import type { RouteChainNode } from "@/frontend/components/Hangar/Planner/RouteChain/types";
import { usePlanMoney } from "@/frontend/components/Hangar/Planner/format";
import { useElementSize } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useComlink } from "@/shared/composables/useComlink";
import { useModalDirty } from "@/shared/components/AppModal/dirty";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import { useBuybackInsurance } from "@/frontend/composables/useBuybackInsurance";
import {
  type HangarPlanAcquisition,
  type HangarPlanBuybackResource,
  type HangarPlanCandidate,
  type HangarPlanModel,
  BuybackPledgeKindEnum,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
  useCreateHangarPlanAcquisition,
  useHangarPlan,
  useHangarPlanResources,
  useUpdateHangarPlanAcquisition,
} from "@/services/fyApi";

type Props = {
  planId: string;
  candidate: HangarPlanCandidate;
  acquisition?: HangarPlanAcquisition;
};

type StepDraft = {
  key: number;
  sourceKind: HangarPlanUpgradeSourceEnum;
  toModelId: string | null;
  hangarPledgeItemId: string | null;
  buybackPledgeId: string | null;
  priceOverride: string;
  // The owned or bought-back upgrade, by its RSI title, when the step uses one.
  sourceName?: string;
  price?: number | null;
  // An RSI title naming a ship we could not match leaves the target to the user.
  pickTarget?: boolean;
  // Lists every held upgrade of the step's kind, not only those starting where
  // the step does, for a title whose first ship we could not match.
  showAll?: boolean;
  // Built from the target back, a step names the ship it starts from and takes
  // its target from the step after it.
  fromModelId?: string | null;
  pickFrom?: boolean;
  // A bought-back upgrade paid with store credit, which spends a token.
  usesBuybackToken?: boolean;
};

type Direction = "forward" | "reverse";

type UpgradeOption = PickListItem & {
  sourceKind: HangarPlanUpgradeSourceEnum;
  fromId?: string;
  toId?: string;
  priceValue?: number | null;
};

const props = defineProps<Props>();

const { t, toDollar } = useI18n();
const { money } = usePlanMoney();
// A share of the bill reads as an amount even when it is nothing, which
// toDollar renders as a dash.
const payable = (value: number | null) => {
  if (value === null) return money(value);

  return value === 0 ? "$0" : toDollar(value);
};
const { displayAlert } = useAppNotifications();
const comlink = useComlink();
const { updatePlan } = useHangarPlanCache();

const { data: resources, isLoading: resourcesLoading } = useHangarPlanResources(
  () => props.planId,
);

const { data: plan } = useHangarPlan(() => props.planId);

const isEdit = computed(() => !!props.acquisition);

const submitting = ref(false);
const errorMessages = ref<string[]>([]);
const target = computed(() => props.candidate.model);

let stepKey = 0;

const startKind = ref<HangarPlanStartKindEnum>(
  props.acquisition?.startKind ?? HangarPlanStartKindEnum.OWNED,
);
const sourceVehicleId = ref<string | null>(
  props.acquisition?.sourceVehicleId ?? null,
);
const buybackPledgeId = ref<string | null>(
  props.acquisition?.buybackPledgeId ?? null,
);
const startModelId = ref<string | null>(
  props.acquisition?.startModel.id ?? props.candidate.model.id,
);
const priceOverride = ref<string>(
  props.acquisition?.priceOverride?.toString() ?? "",
);
const startUsesToken = ref<boolean>(
  props.acquisition?.usesBuybackToken ?? false,
);
const steps = ref<StepDraft[]>(
  (props.acquisition?.steps ?? []).map((step) => ({
    key: stepKey++,
    sourceKind: step.sourceKind,
    toModelId: step.toModel.id,
    hangarPledgeItemId: step.hangarPledgeItemId ?? null,
    buybackPledgeId: step.buybackPledgeId ?? null,
    priceOverride: step.priceOverride?.toString() ?? "",
    price: step.price,
    usesBuybackToken: step.usesBuybackToken,
  })),
);

// Forward, the route grows from where the ship comes from; in reverse, from the
// target back, one upgrade into the next, until it meets a start.
const direction = ref<Direction>("forward");

// Ordered from the target back: the first ends on the target.
const backSteps = ref<StepDraft[]>([]);

const backTo = (index: number) =>
  index === 0
    ? target.value.id
    : (backSteps.value[index - 1].fromModelId ?? null);

const chainHead = computed(() => {
  const last = backSteps.value[backSteps.value.length - 1];
  return last ? (last.fromModelId ?? null) : target.value.id;
});

const reverse = computed(() => direction.value === "reverse");

const directions: Direction[] = ["forward", "reverse"];

const pickDirection = (next: Direction) => {
  if (direction.value === next) return;

  direction.value = next;
  steps.value = [];
  backSteps.value = [];
  sourceVehicleId.value = null;
  buybackPledgeId.value = null;
  startModelId.value = props.candidate.model.id;
  if (next === "reverse" && !resourcesLoading.value) addBackStep();
};

// The first question in reverse is always the same, so it is asked at once.
watch(resourcesLoading, (loadingNow) => {
  if (!loadingNow && reverse.value && !backSteps.value.length) addBackStep();
});

const startSection = ref<HTMLElement>();

const startFromHead = () => {
  startSection.value?.scrollIntoView({ behavior: "smooth", block: "start" });
};

const touched = ref(false);
watch(
  [
    startKind,
    sourceVehicleId,
    buybackPledgeId,
    startModelId,
    priceOverride,
    steps,
    backSteps,
    direction,
    startUsesToken,
  ],
  () => {
    touched.value = true;
  },
  { deep: true },
);
useModalDirty(touched);

// Every ship the dialog can name, so the route reads in names however each
// stop was picked.
const pickedNames = ref<Record<string, string>>({});
const models = computed(() => {
  const known = new Map<string, HangarPlanModel>();
  const add = (model?: HangarPlanModel) => {
    if (model) known.set(model.id, model);
  };

  add(props.candidate.model);
  add(props.acquisition?.startModel);
  props.acquisition?.steps.forEach((step) => {
    add(step.fromModel);
    add(step.toModel);
  });
  resources.value?.vehicles.forEach((vehicle) => add(vehicle.model));
  resources.value?.storeModels.forEach(add);
  resources.value?.upgrades.forEach((item) => {
    add(item.fromModel);
    add(item.toModel);
  });
  resources.value?.buybacks.forEach((pledge) => {
    pledge.models.forEach(add);
    add(pledge.upgradeFromModel);
    add(pledge.upgradeToModel);
  });

  return known;
});

const nameOf = (id?: string | null) =>
  id
    ? (models.value.get(id)?.name ?? pickedNames.value[id] ?? undefined)
    : undefined;

const remember = (id: string | null, name?: string) => {
  if (id && name) pickedNames.value = { ...pickedNames.value, [id]: name };
};

const startKinds = [
  {
    value: HangarPlanStartKindEnum.OWNED,
    icon: "fa-light fa-warehouse",
  },
  {
    value: HangarPlanStartKindEnum.BUYBACK,
    icon: "fa-light fa-clock-rotate-left",
  },
  {
    value: HangarPlanStartKindEnum.STORE,
    icon: "fa-light fa-cart-shopping",
  },
  {
    value: HangarPlanStartKindEnum.INGAME,
    icon: "fa-light fa-coins",
  },
];

const pickStartKind = (kind: HangarPlanStartKindEnum) => {
  if (startKind.value === kind) return;

  startKind.value = kind;
  if (!reverse.value) steps.value = [];
  if (
    kind === HangarPlanStartKindEnum.STORE ||
    kind === HangarPlanStartKindEnum.INGAME
  ) {
    startModelId.value = reverse.value
      ? chainHead.value
      : props.candidate.model.id;
  }
};

// Built in reverse, the start is whatever the chain begins with.
watch(chainHead, (head) => {
  if (!reverse.value) return;
  if (
    startKind.value === HangarPlanStartKindEnum.STORE ||
    startKind.value === HangarPlanStartKindEnum.INGAME
  ) {
    startModelId.value = head;
  }
});

// A route in reverse that already takes an upgrade cannot start bought in
// game, which takes none.
// A ship bought in game takes no upgrades, so it is no start for a route that
// already has one picked; the user removes the upgrades first.
const hasPickedUpgrade = computed(() =>
  (reverse.value ? backSteps.value : steps.value).some(
    (step) =>
      !!(
        step.toModelId ||
        step.fromModelId ||
        step.hangarPledgeItemId ||
        step.buybackPledgeId
      ),
  ),
);

const startKindDisabled = (kind: HangarPlanStartKindEnum) =>
  kind === HangarPlanStartKindEnum.INGAME && hasPickedUpgrade.value;

// A route upgrades towards its ship, so a start or an upgrade that already
// costs as much leads nowhere. A ship without a known price is kept: there is
// nothing to rule it out by.
const targetPrice = computed(() => target.value.pledgePrice ?? null);

const belowTarget = (model?: HangarPlanModel) => {
  if (!model) return true;
  if (model.id === target.value.id) return true;
  if (targetPrice.value === null || typeof model.pledgePrice !== "number") {
    return true;
  }
  return model.pledgePrice < targetPrice.value;
};

const priceOf = (id?: string | null) =>
  id ? models.value.get(id)?.pledgePrice : undefined;

const storeItem = (
  model: HangarPlanModel,
  price: number | null | undefined,
): PickListItem => ({
  id: model.id,
  title: model.name,
  meta:
    [
      model.manufacturerName,
      model.onSale ? undefined : t("hangarPlanner.notOnSale"),
    ]
      .filter(Boolean)
      .join(" · ") || undefined,
  price: money(price),
  sortPrice: price,
  badge:
    model.id === target.value.id
      ? t("hangarPlanner.route.isTarget")
      : undefined,
  pinned: model.id === target.value.id,
});

const storeModels = computed(() => resources.value?.storeModels ?? []);

const storeStartItems = computed(() =>
  storeModels.value
    .filter(belowTarget)
    .map((model) => storeItem(model, model.pledgePrice)),
);

const vehicleItems = computed<PickListItem[]>(() =>
  (resources.value?.vehicles ?? [])
    .filter(
      (vehicle) =>
        (!vehicle.usedBy ||
          vehicle.id === props.acquisition?.sourceVehicleId) &&
        belowTarget(vehicle.model) &&
        (!reverse.value || vehicle.model.id === chainHead.value),
    )
    .map((vehicle) => ({
      id: vehicle.id,
      title: vehicle.name || vehicle.model.name,
      price: money(vehicle.model.pledgePrice),
      sortPrice: vehicle.model.pledgePrice,
      meta: vehicle.name
        ? vehicle.model.name
        : (vehicle.model.manufacturerName ?? undefined),
      badge:
        vehicle.model.id === target.value.id
          ? t("hangarPlanner.route.isTarget")
          : undefined,
      pinned: vehicle.model.id === target.value.id,
    })),
);

const shipBuybacks = computed(() =>
  (resources.value?.buybacks ?? []).filter(
    (pledge) =>
      pledge.kind !== BuybackPledgeKindEnum.UPGRADE &&
      (!pledge.used || pledge.id === props.acquisition?.buybackPledgeId) &&
      (!pledge.models.length || pledge.models.some(belowTarget)) &&
      (!reverse.value ||
        pledge.models.some((model) => model.id === chainHead.value)),
  ),
);

const insuranceLabel = useBuybackInsurance();

const buybackFilters = ref({ lti: false, target: false });

const holdsTarget = (pledge: HangarPlanBuybackResource) =>
  pledge.models.some((model) => model.id === target.value.id);

const filteredBuybacks = computed(() =>
  shipBuybacks.value.filter(
    (pledge) =>
      (!buybackFilters.value.lti || pledge.lifetimeInsurance) &&
      (!buybackFilters.value.target || holdsTarget(pledge)),
  ),
);

const buybackCounts = computed(() => ({
  lti: shipBuybacks.value.filter((pledge) => pledge.lifetimeInsurance).length,
  target: shipBuybacks.value.filter(holdsTarget).length,
}));

const buybackItems = computed<PickListItem[]>(() =>
  filteredBuybacks.value.map((pledge) => {
    const ships = pledge.models.map((model) => model.name);

    return {
      id: pledge.id,
      title: pledge.name,
      meta:
        [ships.join(", "), insuranceLabel(pledge)]
          .filter(Boolean)
          .join(" · ") || undefined,
      keywords: ships.join(" "),
      price: money(pledge.price),
      sortPrice: pledge.price,
      badge: holdsTarget(pledge)
        ? t("hangarPlanner.route.holdsTarget")
        : undefined,
      pinned: holdsTarget(pledge),
    };
  }),
);

const pickedBuyback = computed(() =>
  shipBuybacks.value.find((pledge) => pledge.id === buybackPledgeId.value),
);

const pledgeShips = computed(() =>
  (pickedBuyback.value?.models ?? []).filter(belowTarget),
);

// A pledge returns its ships; the route starts on the one the user names, the
// target when the pledge holds it.
watch(buybackPledgeId, () => {
  const pledge = pickedBuyback.value;
  if (!pledge) return;

  const ships = pledge.models.filter(belowTarget);
  const wanted = reverse.value ? chainHead.value : target.value.id;
  startModelId.value =
    ships.find((model) => model.id === wanted)?.id ?? ships[0]?.id ?? null;
});

const startModel = computed(() => {
  if (startKind.value === HangarPlanStartKindEnum.OWNED) {
    const vehicle = resources.value?.vehicles.find(
      (entry) => entry.id === sourceVehicleId.value,
    );
    return vehicle?.model.id ?? (isEdit.value ? startModelId.value : null);
  }
  if (startKind.value === HangarPlanStartKindEnum.BUYBACK) {
    return buybackPledgeId.value ? startModelId.value : null;
  }
  return startModelId.value;
});

// The route's upgrades in the order they are taken, however it was built.
const routeSteps = computed<StepDraft[]>(() =>
  reverse.value
    ? backSteps.value
        .map((step, index) => ({ ...step, toModelId: backTo(index) }))
        .reverse()
    : steps.value,
);

// Where the first upgrade starts: the start in forward order, the chain's
// first ship in reverse, which the start has yet to match.
const routeStartId = computed(() =>
  reverse.value && backSteps.value.length ? chainHead.value : startModel.value,
);

const currentModelId = computed(() => {
  const last = routeSteps.value[routeSteps.value.length - 1];
  return last ? last.toModelId : startModel.value;
});

const chainConnected = computed(
  () => !reverse.value || startModel.value === chainHead.value,
);

const startChosen = computed(() => !!startModel.value);

// A ship bought in the game takes no upgrades, so it starts as the target.
const upgradable = computed(
  () => startChosen.value && startKind.value !== HangarPlanStartKindEnum.INGAME,
);

const endsOnCandidate = computed(
  () => currentModelId.value === target.value.id,
);

const stepsComplete = computed(() =>
  reverse.value
    ? backSteps.value.every((step) => !!step.fromModelId)
    : steps.value.every((step) => !!step.toModelId),
);

const canSave = computed(
  () =>
    startChosen.value &&
    endsOnCandidate.value &&
    stepsComplete.value &&
    chainConnected.value,
);

type HeldKey = "hangarPledgeItemId" | "buybackPledgeId";

const stepSources = [
  HangarPlanUpgradeSourceEnum.STORE,
  HangarPlanUpgradeSourceEnum.OWNED_CCU,
  HangarPlanUpgradeSourceEnum.BUYBACK,
];

const sourceIcons: Record<HangarPlanUpgradeSourceEnum, string> = {
  [HangarPlanUpgradeSourceEnum.STORE]: "fa-light fa-cart-shopping",
  [HangarPlanUpgradeSourceEnum.OWNED_CCU]: "fa-light fa-box-open",
  [HangarPlanUpgradeSourceEnum.BUYBACK]: "fa-light fa-clock-rotate-left",
};

// The switches fold to their icons, with the label as a tooltip, once the
// column is too narrow to show every label in full.
const main = ref<HTMLElement>();
const { width: mainWidth } = useElementSize(main);
const compactStart = computed(
  () => mainWidth.value > 0 && mainWidth.value < 480,
);
const compactSource = computed(
  () => mainWidth.value > 0 && mainWidth.value < 480,
);

const stepFromId = (index: number) =>
  index === 0 ? startModel.value : steps.value[index - 1].toModelId;

const usedElsewhere = (key: HeldKey, id: string, step: StepDraft) =>
  (reverse.value ? backSteps.value : steps.value).filter(
    (entry) => entry.key !== step.key && entry[key] === id,
  ).length;

const savedUses = (key: HeldKey, id: string) =>
  (props.acquisition?.steps ?? []).filter((entry) => entry[key] === id).length;

const reachBadge = (model?: HangarPlanModel) =>
  model?.id === target.value.id
    ? t("hangarPlanner.route.reaches", { ship: target.value.name })
    : undefined;

// A ship the user could start a reverse route from right away.
const startBadge = (id?: string) => {
  if (!id) return undefined;
  if (
    (resources.value?.vehicles ?? []).some(
      (vehicle) => !vehicle.usedBy && vehicle.model.id === id,
    )
  ) {
    return t("hangarPlanner.route.inHangar");
  }
  if (
    (resources.value?.buybacks ?? []).some(
      (pledge) =>
        pledge.kind !== BuybackPledgeKindEnum.UPGRADE &&
        !pledge.used &&
        pledge.models.some((model) => model.id === id),
    )
  ) {
    return t("hangarPlanner.route.buybackAvailable");
  }
  return undefined;
};

// Built forward, an upgrade is told apart by where it leads; built from the
// target back, every candidate leads to the same ship, so it is told apart by
// where it starts.
const facingFrom = (option: UpgradeOption, rawName: string): UpgradeOption => {
  const from = option.fromId ? models.value.get(option.fromId) : undefined;

  return {
    ...option,
    title: from?.name ?? rawName,
    meta: [
      from ? undefined : rawName,
      option.toId
        ? t("hangarPlanner.route.upgradesTo", { ship: nameOf(option.toId) })
        : undefined,
      option.meta && option.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU
        ? option.meta.split(" · ").pop()
        : undefined,
    ]
      .filter(Boolean)
      .join(" · "),
    sortPrice: from?.pledgePrice,
    badge: startBadge(option.fromId),
  };
};

// What a step can spend of what the user holds: owned upgrades or bought-back
// ones, each as often as it is still free, leading nowhere dearer than the
// target.
const heldUpgrades = (step: StepDraft, fromSide = false): UpgradeOption[] =>
  heldUpgradeOptions(step).map((option) =>
    fromSide ? facingFrom(option, option.keywords ?? option.title) : option,
  );

const heldUpgradeOptions = (step: StepDraft): UpgradeOption[] => {
  if (step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU) {
    return (resources.value?.upgrades ?? []).flatMap((item) => {
      const left =
        item.quantity -
        item.usedCount +
        savedUses("hangarPledgeItemId", item.id) -
        usedElsewhere("hangarPledgeItemId", item.id, step);
      if (left <= 0) return [];

      return [
        {
          id: item.id,
          title: item.toModel?.name ?? item.name,
          // The RSI title only says more than the ship when we could not
          // match the ship it names.
          meta: [
            item.toModel ? undefined : item.name,
            t("hangarPlanner.route.left", { count: left }),
          ]
            .filter(Boolean)
            .join(" · "),
          keywords: item.name,
          price: money(0),
          sortPrice: item.toModel?.pledgePrice,
          badge: reachBadge(item.toModel),
          pinned: item.toModel?.id === target.value.id,
          sourceKind: step.sourceKind,
          fromId: item.fromModel?.id,
          toId: item.toModel?.id,
          priceValue: 0,
        },
      ];
    });
  }

  if (step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK) {
    return (resources.value?.buybacks ?? []).flatMap((pledge) => {
      if (pledge.kind !== BuybackPledgeKindEnum.UPGRADE) return [];

      const free =
        (!pledge.used || savedUses("buybackPledgeId", pledge.id) > 0) &&
        usedElsewhere("buybackPledgeId", pledge.id, step) === 0;
      if (!free) return [];

      return [
        {
          id: pledge.id,
          title: pledge.upgradeToModel?.name ?? pledge.name,
          meta: pledge.upgradeToModel ? undefined : pledge.name,
          keywords: pledge.name,
          price: money(pledge.price),
          sortPrice: pledge.upgradeToModel?.pledgePrice,
          badge: reachBadge(pledge.upgradeToModel),
          pinned: pledge.upgradeToModel?.id === target.value.id,
          sourceKind: step.sourceKind,
          fromId: pledge.upgradeFromModel?.id,
          toId: pledge.upgradeToModel?.id,
          priceValue: pledge.price,
        },
      ];
    });
  }

  return [];
};

const belowTargetId = (id?: string) =>
  belowTarget(id ? models.value.get(id) : undefined);

const fittingUpgrades = (step: StepDraft, index: number) =>
  heldUpgrades(step).filter(
    (option) =>
      option.fromId &&
      option.fromId === stepFromId(index) &&
      belowTargetId(option.toId),
  );

const listedUpgrades = (step: StepDraft, index: number) =>
  step.showAll
    ? heldUpgrades(step).filter((option) => belowTargetId(option.toId))
    : fittingUpgrades(step, index);

// A later upgrade starts where this one ends, so changing one drops the rest.
const dropAfter = (index: number) => {
  steps.value = steps.value.slice(0, index + 1);
};

const draft = (sourceKind: HangarPlanUpgradeSourceEnum): StepDraft => ({
  key: stepKey++,
  sourceKind,
  toModelId: null,
  hangarPledgeItemId: null,
  buybackPledgeId: null,
  priceOverride: "",
});

const setSource = (index: number, sourceKind: HangarPlanUpgradeSourceEnum) => {
  if (steps.value[index].sourceKind === sourceKind) return;

  steps.value[index] = { ...draft(sourceKind), key: steps.value[index].key };
  dropAfter(index);
};

// A new upgrade starts on what the user holds when something fits, and falls
// back to the store, which always has one.
const addStep = () => {
  const index = steps.value.length;
  const pick = [
    HangarPlanUpgradeSourceEnum.OWNED_CCU,
    HangarPlanUpgradeSourceEnum.BUYBACK,
  ].find((kind) => fittingUpgrades(draft(kind), index).length);

  steps.value.push(draft(pick ?? HangarPlanUpgradeSourceEnum.STORE));
};

// Anything between the ship and the target is an upgrade, so while the route
// stops short of the target the next one is asked for at once.
watch(
  [
    reverse,
    upgradable,
    stepsComplete,
    endsOnCandidate,
    resourcesLoading,
    () => steps.value.length,
  ],
  () => {
    if (
      !reverse.value &&
      upgradable.value &&
      stepsComplete.value &&
      !endsOnCandidate.value &&
      !resourcesLoading.value
    ) {
      addStep();
    }
  },
  { immediate: true },
);

const pickHeld = (index: number, item: PickListItem) => {
  const step = steps.value[index];
  const option = heldUpgrades(step).find((entry) => entry.id === item.id);
  if (!option) return;

  const owned = step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU;
  steps.value[index] = {
    ...step,
    toModelId: option.toId ?? null,
    hangarPledgeItemId: owned ? option.id : null,
    buybackPledgeId: owned ? null : option.id,
    sourceName: option.keywords,
    price: option.priceValue,
    pickTarget: !option.toId,
  };
  dropAfter(index);
};

const pickStoreTarget = (index: number, name?: string) => {
  remember(steps.value[index].toModelId, name);
  dropAfter(index);
};

// A store upgrade leads from where the step starts to something dearer, short
// of the target, or to the target itself, and costs the difference.
const storeStepItems = (index: number) => {
  const fromId = stepFromId(index);
  const from = priceOf(fromId);

  return storeModels.value
    .filter(
      (model) =>
        model.id !== fromId &&
        belowTarget(model) &&
        (typeof from !== "number" || (model.pledgePrice ?? 0) > from),
    )
    .map((model) =>
      storeItem(
        model,
        typeof from === "number" && typeof model.pledgePrice === "number"
          ? model.pledgePrice - from
          : null,
      ),
    );
};

// The last upgrade is what reaches the target, so it can be changed but not
// dropped, unless the route starts on the target already.
const removable = (index: number) =>
  index < steps.value.length - 1 || startModel.value === target.value.id;

const removeStep = (key: number) => {
  const index = steps.value.findIndex((step) => step.key === key);
  steps.value = steps.value.slice(0, index);
};

// Built back, a store upgrade is chosen by the ship it starts from: anything
// cheaper than where it ends.
const storeBackItems = (index: number) => {
  const toId = backTo(index);
  const to = priceOf(toId);

  return storeModels.value
    .filter(
      (model) =>
        model.id !== toId &&
        (typeof to !== "number" || (model.pledgePrice ?? 0) < to),
    )
    .map((model) =>
      storeItem(
        model,
        typeof to === "number" && typeof model.pledgePrice === "number"
          ? to - model.pledgePrice
          : null,
      ),
    );
};

const cheaperThan = (fromId?: string, toId?: string | null) => {
  const from = fromId ? models.value.get(fromId)?.pledgePrice : undefined;
  const to = toId ? models.value.get(toId)?.pledgePrice : undefined;
  return typeof from !== "number" || typeof to !== "number" || from < to;
};

// In reverse, an upgrade is chosen by where it ends: the ship the step after it
// starts from, the target for the last one.
const fittingBackUpgrades = (step: StepDraft, index: number) =>
  heldUpgrades(step, true).filter(
    (option) =>
      option.toId &&
      option.toId === backTo(index) &&
      cheaperThan(option.fromId, option.toId),
  );

const listedBackUpgrades = (step: StepDraft, index: number) =>
  step.showAll ? heldUpgrades(step, true) : fittingBackUpgrades(step, index);

// An earlier upgrade ends where this one starts, so changing one drops those
// further back.
const dropBackAfter = (index: number) => {
  backSteps.value = backSteps.value.slice(0, index + 1);
};

const backDraft = (sourceKind: HangarPlanUpgradeSourceEnum): StepDraft => ({
  ...draft(sourceKind),
  toModelId: null,
  fromModelId: null,
});

const setBackSource = (
  index: number,
  sourceKind: HangarPlanUpgradeSourceEnum,
) => {
  if (backSteps.value[index].sourceKind === sourceKind) return;

  backSteps.value[index] = {
    ...backDraft(sourceKind),
    key: backSteps.value[index].key,
  };
  dropBackAfter(index);
};

const addBackStep = () => {
  const index = backSteps.value.length;
  const pick = [
    HangarPlanUpgradeSourceEnum.OWNED_CCU,
    HangarPlanUpgradeSourceEnum.BUYBACK,
  ].find((kind) => fittingBackUpgrades(backDraft(kind), index).length);

  backSteps.value.push(backDraft(pick ?? HangarPlanUpgradeSourceEnum.STORE));
};

const pickHeldBack = (index: number, item: PickListItem) => {
  const step = backSteps.value[index];
  const option = heldUpgrades(step).find((entry) => entry.id === item.id);
  if (!option) return;

  const owned = step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU;
  backSteps.value[index] = {
    ...step,
    fromModelId: option.fromId ?? null,
    hangarPledgeItemId: owned ? option.id : null,
    buybackPledgeId: owned ? null : option.id,
    sourceName: option.keywords,
    price: option.priceValue,
    pickFrom: !option.fromId,
  };
  dropBackAfter(index);
};

const pickBackFrom = (index: number, name?: string) => {
  remember(backSteps.value[index].fromModelId ?? null, name);
  dropBackAfter(index);
};

// Each upgrade added in reverse comes earlier in the route, so the cards read
// top to bottom in the order the upgrades are taken, the newest on top.
const backStepsInRouteOrder = computed(() =>
  backSteps.value.map((step, index) => ({ step, index })).reverse(),
);

const canAddBackStep = computed(
  () =>
    !resourcesLoading.value &&
    backSteps.value.every((step) => !!step.fromModelId),
);

const removeBackStep = (key: number) => {
  const index = backSteps.value.findIndex((step) => step.key === key);
  backSteps.value = backSteps.value.slice(0, index);
};

const backStepInfo = (step: StepDraft, index: number) =>
  stepInfo({ ...step, toModelId: backTo(index) }, -1, step.fromModelId);

const toPrice = (value: string) => (value === "" ? null : Number(value));

const storeStepPrice = (step: StepDraft, fromId: string | null) => {
  const override = toPrice(step.priceOverride);
  if (override !== null) return override;

  const from = fromId ? models.value.get(fromId)?.pledgePrice : undefined;
  const to = step.toModelId
    ? models.value.get(step.toModelId)?.pledgePrice
    : undefined;
  if (typeof from === "number" && typeof to === "number") {
    return Math.max(0, to - from);
  }
  return step.price ?? null;
};

const startPrice = computed(() => {
  const override = toPrice(priceOverride.value);
  switch (startKind.value) {
    case HangarPlanStartKindEnum.OWNED:
    case HangarPlanStartKindEnum.INGAME:
      return 0;
    case HangarPlanStartKindEnum.BUYBACK:
      return override ?? pickedBuyback.value?.price ?? null;
    default:
      return (
        override ??
        (startModel.value
          ? models.value.get(startModel.value)?.pledgePrice
          : null) ??
        null
      );
  }
});

const stepPrices = computed(() => {
  let fromId = routeStartId.value;

  return routeSteps.value.map((step) => {
    const price =
      step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
        ? storeStepPrice(step, fromId)
        : step.sourceKind === HangarPlanUpgradeSourceEnum.OWNED_CCU
          ? 0
          : (toPrice(step.priceOverride) ?? step.price ?? null);
    fromId = step.toModelId;

    return price;
  });
});

// An unknown price leaves its total unknown rather than quietly lower.
const sum = (prices: (number | null | undefined)[]) =>
  prices.some((price) => price === null || price === undefined)
    ? null
    : prices.reduce<number>((total, price) => total + (price ?? 0), 0);

const totals = computed(() => {
  const upgrades = sum(stepPrices.value);

  return {
    start: startPrice.value,
    upgrades,
    spend: sum([startPrice.value, upgrades]),
  };
});

// RSI takes store credit for the store, and for a buy-back only against a
// token. VAT is charged on new money; credit was taxed when it was bought.
const payment = computed(() => {
  const credit: (number | null)[] = [];
  const cash: (number | null)[] = [];

  if (startKind.value === HangarPlanStartKindEnum.STORE) {
    credit.push(startPrice.value);
  } else if (startKind.value === HangarPlanStartKindEnum.BUYBACK) {
    (startUsesToken.value ? credit : cash).push(startPrice.value);
  }

  routeSteps.value.forEach((step, index) => {
    if (step.sourceKind === HangarPlanUpgradeSourceEnum.STORE) {
      credit.push(stepPrices.value[index]);
    } else if (step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK) {
      (step.usesBuybackToken ? credit : cash).push(stepPrices.value[index]);
    }
  });

  const cashTotal = sum(cash);
  const rate = plan.value?.vatRate ?? null;
  const vat =
    rate && cashTotal !== null ? Math.round(cashTotal * rate) / 100 : null;

  return {
    credit: sum(credit),
    cash: cashTotal,
    rate,
    vat,
    cashWithVat: vat === null ? cashTotal : sum([cashTotal, vat]),
  };
});

const nodes = computed<RouteChainNode[]>(() => {
  const pendingStart = reverse.value && !chainConnected.value;
  if (!startChosen.value && !(reverse.value && backSteps.value.length)) {
    return [];
  }

  return [
    pendingStart
      ? {
          key: "start",
          kind: t("hangarPlanner.route.startPending"),
          ship: nameOf(chainHead.value) ?? "…",
        }
      : {
          key: "start",
          kind: t(`hangarPlanner.startKinds.${startKind.value}`),
          ship: nameOf(startModel.value) ?? t("hangarPlanner.unknownPrice"),
          price: money(startPrice.value),
        },
    ...routeSteps.value.map((step, index) => ({
      key: String(step.key),
      kind: t("hangarPlanner.stepNumber", { number: index + 1 }),
      ship: nameOf(step.toModelId) ?? "…",
      link: {
        source: t(`hangarPlanner.upgradeSources.${step.sourceKind}`),
        price: money(stepPrices.value[index]),
      },
    })),
  ];
});

const stepInfo = (step: StepDraft, index: number, fromId?: string | null) => {
  switch (step.sourceKind) {
    case HangarPlanUpgradeSourceEnum.STORE:
      return t("hangarPlanner.route.todaysPrice", {
        price: money(
          storeStepPrice(
            step,
            fromId !== undefined ? fromId : stepFromId(index),
          ),
        ),
      });
    case HangarPlanUpgradeSourceEnum.OWNED_CCU:
      return step.hangarPledgeItemId
        ? t("hangarPlanner.route.ownedPaid")
        : undefined;
    default:
      if (!step.buybackPledgeId) return undefined;

      return step.usesBuybackToken
        ? `${money(step.price)} · ${t("hangarPlanner.route.withToken")}`
        : money(step.price);
  }
};

const stepInputs = () =>
  routeSteps.value.map((step) => ({
    sourceKind: step.sourceKind,
    toModelId: step.toModelId as string,
    hangarPledgeItemId: step.hangarPledgeItemId,
    buybackPledgeId: step.buybackPledgeId,
    priceOverride: toPrice(step.priceOverride),
    usesBuybackToken:
      step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK &&
      !!step.usesBuybackToken,
  }));

const startInputs = () => ({
  startKind: startKind.value,
  sourceVehicleId:
    startKind.value === HangarPlanStartKindEnum.OWNED
      ? sourceVehicleId.value
      : null,
  buybackPledgeId:
    startKind.value === HangarPlanStartKindEnum.BUYBACK
      ? buybackPledgeId.value
      : null,
  startModelId:
    startKind.value === HangarPlanStartKindEnum.OWNED
      ? null
      : startModelId.value,
});

const startTokenInput = () =>
  startKind.value === HangarPlanStartKindEnum.BUYBACK && startUsesToken.value;

const createMutation = useCreateHangarPlanAcquisition();
const updateMutation = useUpdateHangarPlanAcquisition();

const onSubmit = async () => {
  if (!canSave.value) return;

  submitting.value = true;
  errorMessages.value = [];

  try {
    const plan = props.acquisition
      ? await updateMutation.mutateAsync({
          hangarPlanId: props.planId,
          id: props.acquisition.id,
          data: {
            ...startInputs(),
            priceOverride: toPrice(priceOverride.value),
            usesBuybackToken: startTokenInput(),
            steps: stepInputs(),
          },
        })
      : await createMutation.mutateAsync({
          hangarPlanId: props.planId,
          data: {
            candidateId: props.candidate.id,
            startKind: startKind.value,
            sourceVehicleId:
              startKind.value === HangarPlanStartKindEnum.OWNED
                ? sourceVehicleId.value
                : null,
            buybackPledgeId:
              startKind.value === HangarPlanStartKindEnum.BUYBACK
                ? buybackPledgeId.value
                : null,
            startModelId:
              startKind.value === HangarPlanStartKindEnum.OWNED
                ? null
                : startModelId.value,
            priceOverride: toPrice(priceOverride.value),
            usesBuybackToken: startTokenInput(),
            steps: stepInputs(),
          },
        });

    updatePlan(plan);
    comlink.emit("close-modal", true);
  } catch (error) {
    const response = (
      error as {
        response?: {
          data?: { errors?: { messages?: { message?: string }[] }[] };
        };
      }
    ).response;
    errorMessages.value = (response?.data?.errors ?? [])
      .flatMap((entry) => entry.messages ?? [])
      .map((entry) => entry.message)
      .filter((message): message is string => !!message);
    displayAlert({ text: t("hangarPlanner.messages.saveFailed") });
  } finally {
    submitting.value = false;
  }
};
</script>

<template>
  <Modal
    :loading="resourcesLoading || submitting"
    :title="
      t(isEdit ? 'hangarPlanner.editRoute' : 'hangarPlanner.addRoute', {
        ship: target.name,
      })
    "
  >
    <form
      id="hangar-plan-route-form"
      class="route-layout"
      @submit.prevent="onSubmit"
    >
      <div ref="main" class="route-main">
        <section class="route-section">
          <BtnGroup
            segmented
            :size="BtnSizesEnum.SM"
            :aria-label="t('hangarPlanner.route.direction.label')"
          >
            <Btn
              v-for="entry in directions"
              :key="entry"
              :active="direction === entry"
              :data-test="`hangar-plan-route-direction-${entry}`"
              @click="pickDirection(entry)"
            >
              {{ t(`hangarPlanner.route.direction.${entry}`) }}
            </Btn>
          </BtnGroup>
          <p class="route-muted">
            {{
              t(`hangarPlanner.route.directionHints.${direction}`, {
                ship: target.name,
              })
            }}
          </p>
        </section>

        <div class="route-flow">
          <section
            ref="startSection"
            class="route-card"
            data-test="hangar-plan-route-ship-card"
          >
            <div class="route-step__head">
              <span class="route-step__number">
                {{ t("hangarPlanner.route.shipCard") }}
              </span>
              <BtnGroup
                segmented
                :size="BtnSizesEnum.SM"
                :aria-label="t('hangarPlanner.route.shipCard')"
              >
                <Btn
                  v-for="kind in startKinds"
                  :key="kind.value"
                  v-tooltip="
                    startKindDisabled(kind.value)
                      ? t('hangarPlanner.route.ingameNoUpgrades')
                      : compactStart
                        ? t(`hangarPlanner.startKinds.${kind.value}`)
                        : undefined
                  "
                  :active="startKind === kind.value"
                  :disabled="startKindDisabled(kind.value)"
                  :data-test="`hangar-plan-route-start-${kind.value}`"
                  @click="pickStartKind(kind.value)"
                >
                  <i :class="kind.icon" />
                  <span :class="{ 'sr-only': compactStart }">
                    {{ t(`hangarPlanner.route.startShort.${kind.value}`) }}
                  </span>
                </Btn>
              </BtnGroup>
            </div>
            <p
              v-if="
                !startChosen || startKind === HangarPlanStartKindEnum.INGAME
              "
              class="route-muted"
            >
              {{
                t(`hangarPlanner.route.startHints.${startKind}`, {
                  ship: target.name,
                })
              }}
            </p>
            <p v-if="reverse && backSteps.length" class="route-muted">
              {{
                t("hangarPlanner.route.reverseStart", {
                  ship: nameOf(chainHead) ?? "…",
                })
              }}
            </p>

            <template v-if="true">
              <PickList
                v-if="startKind === HangarPlanStartKindEnum.OWNED"
                v-model="sourceVehicleId"
                name="sourceVehicleId"
                :loading="resourcesLoading"
                :items="vehicleItems"
                :empty="t('hangarPlanner.route.noVehicles')"
              />

              <template v-if="startKind === HangarPlanStartKindEnum.BUYBACK">
                <PickList
                  v-model="buybackPledgeId"
                  name="buybackPledgeId"
                  :loading="resourcesLoading"
                  :items="buybackItems"
                  :empty="
                    shipBuybacks.length
                      ? t('hangarPlanner.route.noMatch')
                      : t('hangarPlanner.route.noBuybacks')
                  "
                >
                  <template v-if="shipBuybacks.length" #filters>
                    <div
                      class="route-filters"
                      role="group"
                      :aria-label="t('hangarPlanner.fields.filters')"
                    >
                      <Chip
                        :state="
                          buybackFilters.lti
                            ? ChipStatesEnum.INCLUDED
                            : ChipStatesEnum.NEUTRAL
                        "
                        :count="buybackCounts.lti"
                        :disabled="!buybackCounts.lti"
                        data-test="hangar-plan-route-filter-lti"
                        @toggle="buybackFilters.lti = !buybackFilters.lti"
                      >
                        {{ t("labels.buybacks.lifetimeInsurance") }}
                      </Chip>
                      <Chip
                        :state="
                          buybackFilters.target
                            ? ChipStatesEnum.INCLUDED
                            : ChipStatesEnum.NEUTRAL
                        "
                        :count="buybackCounts.target"
                        :disabled="!buybackCounts.target"
                        data-test="hangar-plan-route-filter-target"
                        @toggle="buybackFilters.target = !buybackFilters.target"
                      >
                        {{
                          t("hangarPlanner.route.includesShip", {
                            ship: target.name,
                          })
                        }}
                      </Chip>
                    </div>
                  </template>
                </PickList>
                <div v-if="pledgeShips.length > 1" class="route-field">
                  <span class="route-label">
                    {{ t("hangarPlanner.route.pledgeShip") }}
                  </span>
                  <BtnGroup segmented :size="BtnSizesEnum.SM">
                    <Btn
                      v-for="model in pledgeShips"
                      :key="model.id"
                      :active="startModelId === model.id"
                      @click="startModelId = model.id"
                    >
                      {{ model.name }}
                    </Btn>
                  </BtnGroup>
                </div>
                <ModelSelect
                  v-if="pickedBuyback && !pickedBuyback.models.length"
                  v-model="startModelId"
                  name="startModelId"
                  :label="t('hangarPlanner.route.pledgeShip')"
                  @pick="(name) => remember(startModelId, name)"
                />
              </template>

              <div
                v-if="reverse && startKind === HangarPlanStartKindEnum.STORE"
                class="route-field"
              >
                <span class="route-label">
                  {{ t("hangarPlanner.fields.startModel") }}
                </span>
                <div class="route-step__fixed">
                  <span>{{ nameOf(chainHead) ?? "…" }}</span>
                  <i class="fa-solid fa-lock" aria-hidden="true" />
                </div>
              </div>
              <PickList
                v-else-if="startKind === HangarPlanStartKindEnum.STORE"
                v-model="startModelId"
                name="startModelId"
                :loading="resourcesLoading"
                :items="storeStartItems"
                :empty="t('hangarPlanner.route.noStoreShip')"
              />
              <p
                v-if="
                  !reverse &&
                  targetPrice !== null &&
                  startKind === HangarPlanStartKindEnum.STORE
                "
                class="route-muted route-limit"
              >
                {{
                  t("hangarPlanner.route.cheaperOnly", {
                    ship: target.name,
                    price: money(targetPrice),
                  })
                }}
                <Btn
                  v-if="startModelId !== target.id"
                  :size="BtnSizesEnum.XS"
                  :variant="BtnVariantsEnum.BARE"
                  @click="startModelId = target.id"
                >
                  {{
                    t("hangarPlanner.route.buyTarget", { ship: target.name })
                  }}
                </Btn>
              </p>
            </template>

            <div
              v-if="
                startKind === HangarPlanStartKindEnum.STORE ||
                startKind === HangarPlanStartKindEnum.BUYBACK
              "
              class="route-step__options"
            >
              <FormInput
                v-model="priceOverride"
                name="priceOverride"
                :type="InputTypesEnum.NUMBER"
                :min="0"
                :step="0.01"
                prefix="$"
                :label="t('hangarPlanner.fields.priceOverride')"
                :placeholder="t('hangarPlanner.fields.priceOverride')"
                class="route-step__price"
                no-label
                standalone
              />
              <template v-if="startKind === HangarPlanStartKindEnum.BUYBACK">
                <FormCheckbox
                  class="route-step__token"
                  v-model="startUsesToken"
                  name="usesBuybackToken"
                  :label="t('hangarPlanner.route.useToken')"
                  data-test="hangar-plan-route-start-token"
                />
              </template>
            </div>
          </section>

          <section v-if="!reverse && upgradable" class="route-flow__steps">
            <ol v-if="steps.length" class="route-steps">
              <li
                v-for="(step, index) in steps"
                :key="step.key"
                class="route-step"
                data-test="hangar-plan-route-step"
              >
                <div class="route-step__head">
                  <span class="route-step__number">
                    {{ t("hangarPlanner.stepNumber", { number: index + 1 }) }}
                  </span>
                  <BtnGroup
                    segmented
                    :size="BtnSizesEnum.SM"
                    :aria-label="t('hangarPlanner.fields.upgradeSource')"
                  >
                    <Btn
                      v-for="kind in stepSources"
                      :key="kind"
                      v-tooltip="
                        compactSource
                          ? t(`hangarPlanner.upgradeSources.${kind}`)
                          : undefined
                      "
                      :active="step.sourceKind === kind"
                      :data-test="`hangar-plan-route-step-source-${kind}`"
                      @click="setSource(index, kind)"
                    >
                      <i :class="sourceIcons[kind]" />
                      <span :class="{ 'sr-only': compactSource }">
                        {{ t(`hangarPlanner.upgradeSources.${kind}`) }}
                      </span>
                    </Btn>
                  </BtnGroup>
                  <Btn
                    :size="BtnSizesEnum.XS"
                    :variant="BtnVariantsEnum.BARE"
                    :tone="BtnTonesEnum.DANGER"
                    :aria-label="t('hangarPlanner.removeStep')"
                    class="route-step__remove"
                    :class="{ invisible: !removable(index) }"
                    :disabled="!removable(index)"
                    @click="removeStep(step.key)"
                  >
                    <i class="fa-light fa-trash" />
                  </Btn>
                </div>

                <div class="route-step__line">
                  <p class="route-step__fixed-line">
                    <span class="route-muted">
                      {{ t("hangarPlanner.route.from") }}
                    </span>
                    <strong class="route-step__name">
                      {{ nameOf(stepFromId(index)) ?? "…" }}
                    </strong>
                  </p>
                  <i
                    class="fa-light fa-arrow-right route-step__arrow"
                    aria-hidden="true"
                  />
                  <div class="route-step__picker">
                    <template
                      v-if="
                        step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
                      "
                    >
                      <PickList
                        :name="`steps.${index}.toModelId`"
                        compact
                        :loading="resourcesLoading"
                        :model-value="step.toModelId"
                        :items="storeStepItems(index)"
                        :empty="t('hangarPlanner.route.noStoreShip')"
                        @pick="
                          (item) => {
                            step.toModelId = item.id;
                            pickStoreTarget(index);
                          }
                        "
                      />
                    </template>
                    <template v-else>
                      <PickList
                        :name="`steps.${index}.upgrade`"
                        compact
                        :loading="resourcesLoading"
                        :model-value="
                          step.hangarPledgeItemId ?? step.buybackPledgeId
                        "
                        :items="listedUpgrades(step, index)"
                        :empty="
                          t(`hangarPlanner.route.noHeld.${step.sourceKind}`, {
                            ship: nameOf(stepFromId(index)),
                          })
                        "
                        @pick="(item) => pickHeld(index, item)"
                      />
                      <Btn
                        v-if="
                          !(step.hangarPledgeItemId || step.buybackPledgeId) &&
                          heldUpgrades(step).length >
                            fittingUpgrades(step, index).length
                        "
                        :size="BtnSizesEnum.XS"
                        :variant="BtnVariantsEnum.BARE"
                        class="self-start"
                        data-test="hangar-plan-route-all-upgrades"
                        @click="step.showAll = !step.showAll"
                      >
                        {{
                          step.showAll
                            ? t("hangarPlanner.route.showFitting")
                            : t("hangarPlanner.route.showAll", {
                                count: heldUpgrades(step).length,
                              })
                        }}
                      </Btn>
                      <ModelSelect
                        v-if="step.pickTarget"
                        v-model="step.toModelId"
                        :name="`steps.${index}.toModelId`"
                        no-label
                        class="route-step__select"
                        :label="t('hangarPlanner.route.unknownTarget')"
                        @pick="(name) => pickStoreTarget(index, name)"
                      />
                    </template>
                  </div>
                </div>
                <div class="route-step__options">
                  <FormInput
                    v-if="
                      step.sourceKind !== HangarPlanUpgradeSourceEnum.OWNED_CCU
                    "
                    v-model="step.priceOverride"
                    :name="`steps.${index}.priceOverride`"
                    :type="InputTypesEnum.NUMBER"
                    :min="0"
                    :step="0.01"
                    prefix="$"
                    :label="t('hangarPlanner.fields.priceOverride')"
                    :placeholder="t('hangarPlanner.fields.priceOverride')"
                    class="route-step__price"
                    no-label
                    standalone
                  />
                  <FormCheckbox
                    class="route-step__token"
                    v-if="
                      step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK
                    "
                    v-model="step.usesBuybackToken"
                    :name="`steps.${index}.usesBuybackToken`"
                    :label="t('hangarPlanner.route.useToken')"
                    :data-test="`hangar-plan-route-steps-token`"
                  />
                  <span
                    v-if="
                      step.sourceKind === HangarPlanUpgradeSourceEnum.STORE &&
                      stepInfo(step, index)
                    "
                    class="route-muted"
                  >
                    {{ stepInfo(step, index) }}
                  </span>
                </div>
              </li>
            </ol>
          </section>

          <section v-if="reverse" class="route-flow__steps">
            <div
              v-if="stepsComplete && chainHead !== startModel"
              class="route-next"
              data-test="hangar-plan-route-next"
            >
              <p class="route-muted">
                {{
                  t("hangarPlanner.route.nextStep", {
                    ship: nameOf(chainHead) ?? "…",
                  })
                }}
              </p>
              <div class="route-next__actions">
                <Btn
                  :size="BtnSizesEnum.XS"
                  :disabled="!canAddBackStep"
                  data-test="hangar-plan-route-add-back-step"
                  @click="addBackStep"
                >
                  <i class="fa-light fa-plus" />
                  {{
                    t("hangarPlanner.route.addUpgradeInto", {
                      ship: nameOf(chainHead) ?? "…",
                    })
                  }}
                </Btn>
                <Btn
                  :size="BtnSizesEnum.XS"
                  :variant="BtnVariantsEnum.GHOST"
                  @click="startFromHead"
                >
                  <i class="fa-light fa-arrow-down" />
                  {{
                    t("hangarPlanner.route.startHere", {
                      ship: nameOf(chainHead) ?? "…",
                    })
                  }}
                </Btn>
              </div>
            </div>

            <ol v-if="backSteps.length" class="route-steps">
              <li
                v-for="{ step, index } in backStepsInRouteOrder"
                :key="step.key"
                class="route-step"
                data-test="hangar-plan-route-back-step"
              >
                <div class="route-step__head">
                  <span class="route-step__number">
                    {{
                      t("hangarPlanner.route.upgradeInto", {
                        ship: nameOf(backTo(index)) ?? "…",
                      })
                    }}
                  </span>
                  <BtnGroup
                    segmented
                    :size="BtnSizesEnum.SM"
                    :aria-label="t('hangarPlanner.fields.upgradeSource')"
                  >
                    <Btn
                      v-for="kind in stepSources"
                      :key="kind"
                      v-tooltip="
                        compactSource
                          ? t(`hangarPlanner.upgradeSources.${kind}`)
                          : undefined
                      "
                      :active="step.sourceKind === kind"
                      :data-test="`hangar-plan-route-back-source-${kind}`"
                      @click="setBackSource(index, kind)"
                    >
                      <i :class="sourceIcons[kind]" />
                      <span :class="{ 'sr-only': compactSource }">
                        {{ t(`hangarPlanner.upgradeSources.${kind}`) }}
                      </span>
                    </Btn>
                  </BtnGroup>
                  <Btn
                    :size="BtnSizesEnum.XS"
                    :variant="BtnVariantsEnum.BARE"
                    :tone="BtnTonesEnum.DANGER"
                    :aria-label="t('hangarPlanner.removeStep')"
                    class="route-step__remove"
                    @click="removeBackStep(step.key)"
                  >
                    <i class="fa-light fa-trash" />
                  </Btn>
                </div>

                <div class="route-step__line route-step__line--reverse">
                  <div class="route-step__picker">
                    <PickList
                      v-if="
                        step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
                      "
                      :name="`backSteps.${index}.fromModelId`"
                      compact
                      :loading="resourcesLoading"
                      :model-value="step.fromModelId"
                      :items="storeBackItems(index)"
                      :empty="t('hangarPlanner.route.noStoreShip')"
                      @pick="
                        (item) => {
                          step.fromModelId = item.id;
                          pickBackFrom(index);
                        }
                      "
                    />
                    <template v-else>
                      <PickList
                        :name="`backSteps.${index}.upgrade`"
                        compact
                        :loading="resourcesLoading"
                        :model-value="
                          step.hangarPledgeItemId ?? step.buybackPledgeId
                        "
                        :items="listedBackUpgrades(step, index)"
                        :empty="
                          t(
                            `hangarPlanner.route.noHeldInto.${step.sourceKind}`,
                            {
                              ship: nameOf(backTo(index)),
                            },
                          )
                        "
                        @pick="(item) => pickHeldBack(index, item)"
                      />
                      <Btn
                        v-if="
                          !(step.hangarPledgeItemId || step.buybackPledgeId) &&
                          heldUpgrades(step).length >
                            fittingBackUpgrades(step, index).length
                        "
                        :size="BtnSizesEnum.XS"
                        :variant="BtnVariantsEnum.BARE"
                        class="self-start"
                        @click="step.showAll = !step.showAll"
                      >
                        {{
                          step.showAll
                            ? t("hangarPlanner.route.showFitting")
                            : t("hangarPlanner.route.showAll", {
                                count: heldUpgrades(step).length,
                              })
                        }}
                      </Btn>
                      <ModelSelect
                        v-if="step.pickFrom"
                        v-model="step.fromModelId"
                        :name="`backSteps.${index}.fromModelId`"
                        no-label
                        class="route-step__select"
                        :label="t('hangarPlanner.route.unknownSource')"
                        @pick="(name) => pickBackFrom(index, name)"
                      />
                    </template>
                  </div>
                  <i
                    class="fa-light fa-arrow-right route-step__arrow"
                    aria-hidden="true"
                  />
                  <p class="route-step__fixed-line">
                    <span class="route-muted">
                      {{ t("hangarPlanner.route.to") }}
                    </span>
                    <strong class="route-step__name">
                      {{ nameOf(backTo(index)) ?? "…" }}
                    </strong>
                  </p>
                </div>
                <div class="route-step__options">
                  <FormInput
                    v-if="
                      step.sourceKind !== HangarPlanUpgradeSourceEnum.OWNED_CCU
                    "
                    v-model="step.priceOverride"
                    :name="`backSteps.${index}.priceOverride`"
                    :type="InputTypesEnum.NUMBER"
                    :min="0"
                    :step="0.01"
                    prefix="$"
                    :label="t('hangarPlanner.fields.priceOverride')"
                    :placeholder="t('hangarPlanner.fields.priceOverride')"
                    class="route-step__price"
                    no-label
                    standalone
                  />
                  <FormCheckbox
                    class="route-step__token"
                    v-if="
                      step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK
                    "
                    v-model="step.usesBuybackToken"
                    :name="`backSteps.${index}.usesBuybackToken`"
                    :label="t('hangarPlanner.route.useToken')"
                    :data-test="`hangar-plan-route-backSteps-token`"
                  />
                  <span
                    v-if="
                      step.sourceKind === HangarPlanUpgradeSourceEnum.STORE &&
                      backStepInfo(step, index)
                    "
                    class="route-muted"
                  >
                    {{ backStepInfo(step, index) }}
                  </span>
                </div>
              </li>
            </ol>
          </section>
        </div>

        <Alert
          v-if="!reverse && startChosen && !endsOnCandidate && steps.length"
          variant="warning"
        >
          {{ t("hangarPlanner.routeMustEnd", { ship: target.name }) }}
        </Alert>
        <Alert v-if="errorMessages.length" variant="danger">
          <ul class="route-errors">
            <li v-for="message in errorMessages" :key="message">
              {{ message }}
            </li>
          </ul>
        </Alert>
      </div>

      <aside class="route-side" data-test="hangar-plan-route-preview">
        <h3 class="route-side__title">
          {{ t("hangarPlanner.route.yourRoute") }}
        </h3>
        <RouteChain
          :nodes="nodes"
          :pending="nodes.length && endsOnCandidate ? undefined : target.name"
          vertical
        />
        <p v-if="!nodes.length" class="route-muted">
          {{ t("hangarPlanner.route.startFirst") }}
        </p>
        <dl v-if="startChosen" class="route-totals">
          <dt>{{ t("hangarPlanner.route.startCost") }}</dt>
          <dd>{{ money(totals.start) }}</dd>
          <dt>{{ t("hangarPlanner.upgradeSteps") }}</dt>
          <dd>{{ money(totals.upgrades) }}</dd>
          <dt class="route-totals__sum">
            {{ t("hangarPlanner.summary.spend") }}
          </dt>
          <dd class="route-totals__sum">{{ money(totals.spend) }}</dd>
        </dl>
        <dl
          v-if="startChosen"
          class="route-totals"
          data-test="hangar-plan-route-payment"
        >
          <dt>{{ t("hangarPlanner.route.paidWithCredit") }}</dt>
          <dd>{{ payable(payment.credit) }}</dd>
          <dt>{{ t("hangarPlanner.route.paidWithCash") }}</dt>
          <dd>{{ payable(payment.cash) }}</dd>
          <template v-if="payment.rate">
            <dt>{{ t("hangarPlanner.route.vat", { rate: payment.rate }) }}</dt>
            <dd>{{ payable(payment.vat) }}</dd>
            <dt class="route-totals__sum">
              {{ t("hangarPlanner.route.cashWithVat") }}
            </dt>
            <dd class="route-totals__sum">
              {{ payable(payment.cashWithVat) }}
            </dd>
          </template>
        </dl>
        <p v-if="startChosen" class="route-muted route-totals__hint">
          {{ t("hangarPlanner.route.paymentHint") }}
        </p>
        <p v-if="canSave" class="route-done">
          <i class="fa-light fa-circle-check" />
          {{ t("hangarPlanner.route.done", { ship: target.name }) }}
        </p>
      </aside>
    </form>

    <template #footer>
      <Btn
        :type="BtnTypesEnum.SUBMIT"
        form="hangar-plan-route-form"
        :loading="submitting"
        :disabled="!canSave"
        data-test="hangar-plan-route-save"
      >
        {{ t("actions.save") }}
      </Btn>
    </template>
  </Modal>
</template>

<style lang="scss" scoped>
.route-layout {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 300px;
  gap: 24px;
  align-items: start;

  @media (max-width: 991px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

// Spaced by a gap rather than margins, so nothing trails the last card and the
// dialog scrolls only when the content needs it.
.route-main {
  display: flex;
  flex-direction: column;
  gap: 20px;
  min-width: 0;
}

// The route stays in view while the form beside it scrolls; on a narrow
// screen it leads, since it is what the form is building.
.route-side {
  position: sticky;
  top: 0;
  display: flex;
  flex-direction: column;
  gap: 14px;
  padding: 16px;
  border: 1px solid var(--color-edge-faint);
  border-radius: 12px;
  background: var(--color-gray-black);

  @media (max-width: 991px) {
    position: static;
    order: -1;
  }
}

.route-side__title {
  margin: 0;
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  font-weight: 400;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.route-totals {
  display: grid;
  grid-template-columns: minmax(0, 1fr) auto;
  gap: 6px 10px;
  margin: 0;
  padding-top: 12px;
  border-top: 1px solid var(--color-edge-soft);
  font-size: 0.85rem;

  dt {
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-weight: 600;
    text-align: right;
    color: var(--color-lifted);
  }
}

.route-totals__sum {
  font-size: 1.1rem;
}

.route-totals__hint {
  margin: 0;
  font-size: 0.8rem;
}

dt.route-totals__sum {
  color: var(--color-lifted);
}

.route-limit {
  display: flex;
  flex-wrap: wrap;
  gap: 4px 8px;
  align-items: center;
  font-size: 0.85rem;
}

.route-filters {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
}

.route-section {
  display: flex;
  flex-direction: column;
  gap: 10px;

  h3 {
    margin: 0;
    font-size: 1rem;
    font-weight: 600;
    color: var(--color-lifted);
  }
}

.route-muted {
  margin: 0;
  color: var(--color-text-dim);
}

.route-done {
  margin: 0;
  color: var(--color-success);
}

.route-field {
  display: flex;
  flex-direction: column;
  gap: 6px;
}

.route-label {
  color: var(--color-text);
}

.route-subtitle {
  margin: 4px 0 0;
  font-size: 0.9rem;
  font-weight: 400;
  color: var(--color-text-dim);
}

.route-flow {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

.route-flow__steps {
  display: flex;
  flex-direction: column;
  gap: 20px;
}

// The ship and its upgrades are one chain, so every card hangs from the one
// above it.
.route-card,
.route-steps > li {
  position: relative;
}

.route-card {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.route-flow__steps > :first-child::before,
.route-steps > li + li::before {
  content: "";
  position: absolute;
  top: -21px;
  left: 28px;
  height: 20px;
  border-left: 1px solid var(--color-edge);
}

.route-flow__steps > :first-child {
  position: relative;
}

.route-section__head {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
}

.route-steps {
  display: flex;
  flex-direction: column;
  gap: 20px;
  margin: 0;
  padding: 0;
  list-style: none;
}

.route-step {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.route-step__head {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
  align-items: center;
}

.route-step__remove {
  margin-left: auto;
}

.route-step__fixed-line {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  align-items: baseline;
  margin: 0;

  strong {
    color: var(--color-lifted);
  }

  i {
    font-size: 0.75rem;
    color: var(--color-muted);
  }
}

// The ship a step starts from, or ends on, takes a fixed column, so every
// card's picker is as wide as the next.
.route-step__line {
  display: grid;
  grid-template-columns: minmax(0, 200px) auto minmax(0, 1fr);
  gap: 8px 12px;
  align-items: center;

  .route-step__fixed-line {
    flex-direction: column;
    gap: 0;
    align-items: flex-start;
    min-width: 0;

    .route-muted {
      font-size: 0.75rem;
    }
  }

  .route-step__name {
    max-width: 100%;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  @media (max-width: 575px) {
    grid-template-columns: minmax(0, 1fr);

    .route-step__arrow {
      display: none;
    }
  }
}

.route-step__line--reverse {
  grid-template-columns: minmax(0, 1fr) auto minmax(0, 200px);

  @media (max-width: 575px) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.route-step__arrow {
  font-size: 0.75rem;
  color: var(--color-muted);
}

.route-step__picker {
  display: flex;
  flex-direction: column;
  gap: 6px;
  min-width: 0;
}

// The select keeps a field's bottom margin, which would double the card's gap.
.route-step__picker .route-step__select {
  margin-bottom: 0;
}

.route-step__options {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 16px;
  align-items: center;
}

.route-step__price {
  flex: 0 1 200px;
  margin: 0;
}

// A form checkbox keeps a field's bottom margin, which in this row would lift
// it off the price input's centre line.
.route-step__options .route-step__token {
  margin-bottom: 0;
}

.route-step__done {
  margin-left: auto;
}

.route-step__number {
  font-family: "Orbitron", tahoma, sans-serif;
  font-size: 10px;
  letter-spacing: 0.16em;
  text-transform: uppercase;
  color: var(--color-text-dim);
}

.route-next {
  display: flex;
  flex-direction: column;
  gap: 8px;
  padding: 12px 14px;
  border: 1px dashed var(--color-edge);
  border-radius: 12px;
}

.route-next__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.route-step__summary {
  display: flex;
  gap: 12px;
  align-items: center;
}

.route-step__summary-text {
  display: flex;
  flex: 1;
  flex-direction: column;
  gap: 2px;
  min-width: 0;

  strong {
    color: var(--color-lifted);
  }
}

.route-step__fixed {
  display: flex;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
  min-height: 43px;
  padding: 0 14px;
  border: 1px solid var(--color-edge);
  border-radius: 8px;
  background: var(--color-field);
  color: var(--color-lifted);

  i {
    font-size: 0.75rem;
    color: var(--color-muted);
  }
}

.route-errors {
  margin: 0;
  padding-left: 16px;
}
</style>
