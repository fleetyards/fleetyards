<script lang="ts">
export default {
  name: "HangarPlannerRouteView",
};
</script>

<script lang="ts" setup>
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
import ModelSelect from "@/frontend/components/Hangar/Planner/ModelSelect/index.vue";
import PickList, {
  type PickListItem,
} from "@/frontend/components/Hangar/Planner/PickList/index.vue";
import {
  manufacturerText,
  usePlanMoney,
} from "@/frontend/components/Hangar/Planner/format";
import { PillVariantsEnum } from "@/shared/components/base/Pill/types";
import {
  canEnter,
  entersFrom,
  canLeave,
  ccuNote,
} from "@/frontend/components/Hangar/Planner/reach";
import { useElementSize } from "@vueuse/core";
import { useI18n } from "@/shared/composables/useI18n";
import { useAppNotifications } from "@/shared/composables/useAppNotifications";
import { useHangarPlanCache } from "@/frontend/composables/useHangarPlanCache";
import {
  type HangarPlanAcquisition,
  type HangarPlanCandidate,
  type HangarPlanModel,
  BuybackPledgeKindEnum,
  HangarPlanStartKindEnum,
  HangarPlanUpgradeSourceEnum,
  useHangarPlan,
  useHangarPlanResources,
  useUpdateHangarPlanAcquisition,
} from "@/services/fyApi";

// The chain of upgrades between two ships a row already paired: the start and
// the slot's ship are fixed here, only what leads from one to the other is
// built.
type Props = {
  planId: string;
  candidate: HangarPlanCandidate;
  acquisition: HangarPlanAcquisition;
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

type UpgradeOption = PickListItem & {
  sourceKind: HangarPlanUpgradeSourceEnum;
  fromId?: string;
  toId?: string;
  priceValue?: number | null;
};

const props = defineProps<Props>();

const emit = defineEmits<{
  done: [];
}>();

const { t, toDollar } = useI18n();
const { money } = usePlanMoney();
// A share of the bill reads as an amount even when it is nothing, which
// toDollar renders as a dash.
const payable = (value: number | null) => {
  if (value === null) return money(value);

  return value === 0 ? "$0" : toDollar(value);
};
const { displayAlert } = useAppNotifications();
const { updatePlan } = useHangarPlanCache();

const { data: resources, isLoading: resourcesLoading } = useHangarPlanResources(
  () => props.planId,
);

const { data: plan } = useHangarPlan(() => props.planId);

const submitting = ref(false);
const errorMessages = ref<string[]>([]);
const target = computed(() => props.candidate.model);

let stepKey = 0;

const startKind = computed(() => props.acquisition.startKind);

// A melted pledge bought back is paid like any other buy-back.
const boughtBack = computed(
  () =>
    startKind.value === HangarPlanStartKindEnum.BUYBACK ||
    startKind.value === HangarPlanStartKindEnum.MELTED,
);
const startModelId = computed(() => props.acquisition.startModel.id);
const priceOverride = ref<string>(
  props.acquisition.priceOverride?.toString() ?? "",
);
const startUsesToken = ref<boolean>(
  props.acquisition.usesBuybackToken ?? false,
);
const steps = ref<StepDraft[]>(
  props.acquisition.steps.map((step) => ({
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

const touched = ref(false);

defineExpose({ dirty: touched });

watch(
  [priceOverride, steps, startUsesToken],
  () => {
    touched.value = true;
  },
  { deep: true },
);

// Every ship the dialog can name, so the route reads in names however each
// stop was picked.
const pickedNames = ref<Record<string, string>>({});
const models = computed(() => {
  const known = new Map<string, HangarPlanModel>();
  const add = (model?: HangarPlanModel) => {
    if (model) known.set(model.id, model);
  };

  add(props.candidate.model);
  add(props.acquisition.startModel);
  props.acquisition.steps.forEach((step) => {
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

// A route upgrades towards its ship, so a start or an upgrade that already
// costs as much leads nowhere. A ship without a known price is kept: there is
// nothing to rule it out by. No upgrade leads into or out of a ship RSI sells
// none for, so such a ship is only ever the target bought outright.
const targetPrice = computed(() => target.value.pledgePrice ?? null);

const belowTarget = (model?: HangarPlanModel) => {
  if (!model) return true;
  if (model.id === target.value.id) return true;
  if (!canLeave(model) || !canEnter(target.value)) return false;
  if (!entersFrom(model, target.value)) return false;
  if (targetPrice.value === null || typeof model.pledgePrice !== "number") {
    return true;
  }
  return model.pledgePrice < targetPrice.value;
};

const canLeaveId = (id?: string | null) => {
  const model = id ? models.value.get(id) : undefined;
  return !model || canLeave(model);
};

const entersFromId = (id: string | null | undefined, to: HangarPlanModel) => {
  const model = id ? models.value.get(id) : undefined;
  return !model || entersFrom(model, to);
};

const priceOf = (id?: string | null) =>
  id ? models.value.get(id)?.pledgePrice : undefined;

// An upgrade into the ship says how sure it is that RSI sells one.
const storeItem = (
  model: HangarPlanModel,
  price: number | null | undefined,
  upgradeInto = false,
): PickListItem => ({
  id: model.id,
  title: model.name,
  ship: model,
  meta: manufacturerText(model),
  tags: [
    ...(model.onSale ? [] : [{ label: t("hangarPlanner.notOnSale") }]),
    ...(upgradeInto && ccuNote(model)
      ? [
          {
            label: t(ccuNote(model) as string),
            variant: PillVariantsEnum.WARNING,
          },
        ]
      : []),
  ],
  price: money(price),
  sortPrice: price,
  badge:
    model.id === target.value.id
      ? t("hangarPlanner.route.isTarget")
      : undefined,
  pinned: model.id === target.value.id,
});

const storeModels = computed(() => resources.value?.storeModels ?? []);

const startModel = computed(() => startModelId.value);

// The hangar ship the route starts from, by its own name where it has one.
const startName = computed(() => {
  const vehicle = resources.value?.vehicles.find(
    (entry) => entry.id === props.acquisition.sourceVehicleId,
  );

  return vehicle?.name || props.acquisition.startModel.name;
});

const currentModelId = computed(() => {
  const last = steps.value[steps.value.length - 1];
  return last ? last.toModelId : startModel.value;
});

// A ship bought in the game takes no upgrades.
const upgradable = computed(
  () => startKind.value !== HangarPlanStartKindEnum.INGAME,
);

const endsOnCandidate = computed(
  () => currentModelId.value === target.value.id,
);

const stepsComplete = computed(() =>
  steps.value.every((step) => !!step.toModelId),
);

const canSave = computed(() => endsOnCandidate.value && stepsComplete.value);

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
const compactSource = computed(
  () => mainWidth.value > 0 && mainWidth.value < 480,
);

// Too narrow for the totals beside the steps, they move under them.
const layout = useTemplateRef<HTMLElement>("layout");
const { width: layoutWidth } = useElementSize(layout);
const stacked = computed(
  () => layoutWidth.value > 0 && layoutWidth.value < 620,
);

const stepFromId = (index: number) =>
  index === 0 ? startModel.value : steps.value[index - 1].toModelId;

const usedElsewhere = (key: HeldKey, id: string, step: StepDraft) =>
  steps.value.filter((entry) => entry.key !== step.key && entry[key] === id)
    .length;

const savedUses = (key: HeldKey, id: string) =>
  props.acquisition.steps.filter((entry) => entry[key] === id).length;

const reachBadge = (model?: HangarPlanModel) =>
  model?.id === target.value.id
    ? t("hangarPlanner.route.reaches", { ship: target.value.name })
    : undefined;

// What a step can spend of what the user holds: owned upgrades or bought-back
// ones, each as often as it is still free, leading nowhere dearer than the
// target.
// A held upgrade reads as the pair it joins, "MOLE → Merchantman", the way
// RSI names it; its RSI title stands in where either ship is not matched.
const upgradeTitle = (
  name: string,
  from?: HangarPlanModel | null,
  to?: HangarPlanModel | null,
) => (from && to ? `${from.name} → ${to.name}` : (to?.name ?? name));

const heldUpgrades = (step: StepDraft): UpgradeOption[] => {
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
          title: upgradeTitle(item.name, item.fromModel, item.toModel),
          ship: item.toModel ?? undefined,
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
          title: upgradeTitle(
            pledge.name,
            pledge.upgradeFromModel,
            pledge.upgradeToModel,
          ),
          ship: pledge.upgradeToModel ?? undefined,
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
  usesBuybackToken: true,
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
    upgradable,
    stepsComplete,
    endsOnCandidate,
    resourcesLoading,
    () => steps.value.length,
  ],
  () => {
    if (
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
        canEnter(model) &&
        canLeaveId(fromId) &&
        entersFromId(fromId, model) &&
        belowTarget(model) &&
        (typeof from !== "number" || (model.pledgePrice ?? 0) > from),
    )
    .map((model) =>
      storeItem(
        model,
        typeof from === "number" && typeof model.pledgePrice === "number"
          ? model.pledgePrice - from
          : null,
        true,
      ),
    );
};

// A stop between two steps is a store upgrade, the one source that leads
// anywhere. The steps after it now start from wherever it ends, so an upgrade
// held for their old start is asked for again.
const insertStep = (index: number) => {
  const later = steps.value
    .slice(index)
    .map((step) =>
      step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
        ? step
        : { ...draft(step.sourceKind), key: step.key },
    );

  steps.value = [
    ...steps.value.slice(0, index),
    draft(HangarPlanUpgradeSourceEnum.STORE),
    ...later,
  ];
};

// The last upgrade is what reaches the target, so it can be changed but not
// dropped, unless the route starts on the target already.
const removable = (index: number) =>
  index < steps.value.length - 1 || startModel.value === target.value.id;

const removeStep = (key: number) => {
  const index = steps.value.findIndex((step) => step.key === key);
  steps.value = steps.value.slice(0, index);
};

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
      return (
        override ??
        resources.value?.buybacks.find(
          (pledge) => pledge.id === props.acquisition.buybackPledgeId,
        )?.price ??
        null
      );
    case HangarPlanStartKindEnum.MELTED:
      return override ?? props.acquisition.price ?? null;
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
  let fromId: string | null = startModel.value;

  return steps.value.map((step) => {
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
  } else if (boughtBack.value) {
    (startUsesToken.value ? credit : cash).push(startPrice.value);
  }

  steps.value.forEach((step, index) => {
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

const stepInfo = (step: StepDraft, index: number) => {
  switch (step.sourceKind) {
    case HangarPlanUpgradeSourceEnum.STORE:
      return t("hangarPlanner.route.todaysPrice", {
        price: money(storeStepPrice(step, stepFromId(index))),
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
  steps.value.map((step) => ({
    sourceKind: step.sourceKind,
    toModelId: step.toModelId as string,
    hangarPledgeItemId: step.hangarPledgeItemId,
    buybackPledgeId: step.buybackPledgeId,
    priceOverride: toPrice(step.priceOverride),
    usesBuybackToken:
      step.sourceKind === HangarPlanUpgradeSourceEnum.BUYBACK &&
      !!step.usesBuybackToken,
  }));

const startTokenInput = () => boughtBack.value && startUsesToken.value;

const updateMutation = useUpdateHangarPlanAcquisition();

const onSubmit = async () => {
  if (!canSave.value) return;

  submitting.value = true;
  errorMessages.value = [];

  try {
    const plan = await updateMutation.mutateAsync({
      hangarPlanId: props.planId,
      id: props.acquisition.id,
      data: {
        priceOverride: toPrice(priceOverride.value),
        usesBuybackToken: startTokenInput(),
        steps: stepInputs(),
      },
    });

    updatePlan(plan);
    touched.value = false;
    emit("done");
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
  <div class="panel-view" data-test="hangar-plan-route">
    <form
      id="hangar-plan-route-form"
      class="panel-view__body"
      @submit.prevent="onSubmit"
    >
      <!-- Nothing changes under a save on its way, which would be lost when it lands. -->
      <fieldset :disabled="submitting" class="route-view__fieldset">
        <div
          ref="layout"
          class="route-view"
          :class="{ 'route-view--stacked': stacked }"
        >
          <div ref="main" class="route-view__steps">
            <h3 class="panel-view__label">
              {{ t("hangarPlanner.panel.steps") }}
            </h3>
            <ol class="route-view__chain">
              <li
                class="route-view__stop"
                data-test="hangar-plan-route-ship-card"
              >
                <span class="route-view__stop-name">
                  <strong>{{ startName }}</strong>
                  <span class="panel-view__muted">
                    {{ t(`hangarPlanner.startKinds.${startKind}`) }} ·
                    {{ money(startPrice) }}
                  </span>
                </span>
                <div
                  v-if="
                    startKind === HangarPlanStartKindEnum.STORE || boughtBack
                  "
                  class="route-view__options"
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
                    class="route-view__price"
                    no-label
                    standalone
                  />
                  <FormCheckbox
                    v-if="boughtBack"
                    v-model="startUsesToken"
                    name="usesBuybackToken"
                    :label="t('hangarPlanner.route.useToken')"
                    data-test="hangar-plan-route-start-token"
                  />
                </div>
              </li>

              <template v-if="upgradable">
                <template v-for="(step, index) in steps" :key="step.key">
                  <li class="route-view__link">
                    <Btn
                      v-if="index > 0"
                      :size="BtnSizesEnum.XS"
                      :variant="BtnVariantsEnum.BARE"
                      data-test="hangar-plan-route-insert"
                      @click="insertStep(index)"
                    >
                      <i class="fa-light fa-plus" />
                      {{ t("hangarPlanner.panel.addStop") }}
                    </Btn>
                  </li>
                  <li
                    class="route-view__step"
                    data-test="hangar-plan-route-step"
                  >
                    <div class="route-view__step-head">
                      <span class="panel-view__label">
                        {{
                          t("hangarPlanner.panel.stepPaidWith", {
                            number: index + 1,
                          })
                        }}
                      </span>
                      <Btn
                        :size="BtnSizesEnum.XS"
                        :variant="BtnVariantsEnum.BARE"
                        :tone="BtnTonesEnum.DANGER"
                        :aria-label="t('hangarPlanner.removeStep')"
                        :class="{ invisible: !removable(index) }"
                        :disabled="!removable(index)"
                        @click="removeStep(step.key)"
                      >
                        <i class="fa-light fa-trash" />
                      </Btn>
                    </div>
                    <BtnGroup
                      class="route-view__sources"
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

                    <p class="route-view__from">
                      <span class="panel-view__muted">
                        {{ t("hangarPlanner.route.from") }}
                      </span>
                      <strong>{{ nameOf(stepFromId(index)) ?? "…" }}</strong>
                      <i class="fa-light fa-arrow-right" aria-hidden="true" />
                    </p>
                    <PickList
                      v-if="
                        step.sourceKind === HangarPlanUpgradeSourceEnum.STORE
                      "
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
                        :label="t('hangarPlanner.route.unknownTarget')"
                        @pick="(name) => pickStoreTarget(index, name)"
                      />
                    </template>

                    <div class="route-view__options">
                      <FormInput
                        v-if="
                          step.sourceKind !==
                          HangarPlanUpgradeSourceEnum.OWNED_CCU
                        "
                        v-model="step.priceOverride"
                        :name="`steps.${index}.priceOverride`"
                        :type="InputTypesEnum.NUMBER"
                        :min="0"
                        :step="0.01"
                        prefix="$"
                        :label="t('hangarPlanner.fields.priceOverride')"
                        :placeholder="t('hangarPlanner.fields.priceOverride')"
                        class="route-view__price"
                        no-label
                        standalone
                      />
                      <FormCheckbox
                        v-if="
                          step.sourceKind ===
                          HangarPlanUpgradeSourceEnum.BUYBACK
                        "
                        v-model="step.usesBuybackToken"
                        :name="`steps.${index}.usesBuybackToken`"
                        :label="t('hangarPlanner.route.useToken')"
                        data-test="hangar-plan-route-steps-token"
                      />
                      <span
                        v-if="stepInfo(step, index)"
                        class="panel-view__muted"
                      >
                        {{ stepInfo(step, index) }}
                      </span>
                    </div>
                  </li>
                </template>
              </template>

              <li class="route-view__link" />
              <li
                class="route-view__stop"
                :class="{ 'route-view__stop--done': endsOnCandidate }"
              >
                <span class="route-view__stop-name">
                  <strong>{{ target.name }}</strong>
                  <span class="panel-view__muted">
                    {{ t("hangarPlanner.panel.routeEnd") }}
                  </span>
                </span>
                <i
                  v-if="endsOnCandidate"
                  class="fa-light fa-circle-check route-view__check"
                  :aria-label="
                    t('hangarPlanner.route.done', { ship: target.name })
                  "
                />
              </li>
            </ol>

            <Alert v-if="!endsOnCandidate && steps.length" variant="warning">
              {{ t("hangarPlanner.routeMustEnd", { ship: target.name }) }}
            </Alert>
            <Alert v-if="errorMessages.length" variant="danger">
              <ul class="route-view__errors">
                <li v-for="message in errorMessages" :key="message">
                  {{ message }}
                </li>
              </ul>
            </Alert>
          </div>

          <aside class="route-view__side" data-test="hangar-plan-route-preview">
            <section class="panel-view__block">
              <h3 class="panel-view__label">
                {{ t("hangarPlanner.route.yourRoute") }}
              </h3>
              <dl class="route-view__totals">
                <dt>{{ t("hangarPlanner.route.startCost") }}</dt>
                <dd>{{ money(totals.start) }}</dd>
                <dt>{{ t("hangarPlanner.upgradeSteps") }}</dt>
                <dd>{{ money(totals.upgrades) }}</dd>
                <dt class="route-view__sum">
                  {{ t("hangarPlanner.summary.spend") }}
                </dt>
                <dd class="route-view__sum">{{ money(totals.spend) }}</dd>
              </dl>
            </section>
            <section
              class="panel-view__block"
              data-test="hangar-plan-route-payment"
            >
              <dl class="route-view__totals">
                <dt>{{ t("hangarPlanner.route.paidWithCredit") }}</dt>
                <dd>{{ payable(payment.credit) }}</dd>
                <dt>{{ t("hangarPlanner.route.paidWithCash") }}</dt>
                <dd>{{ payable(payment.cash) }}</dd>
                <template v-if="payment.rate">
                  <dt>
                    {{ t("hangarPlanner.route.vat", { rate: payment.rate }) }}
                  </dt>
                  <dd>{{ payable(payment.vat) }}</dd>
                  <dt class="route-view__sum">
                    {{ t("hangarPlanner.route.cashWithVat") }}
                  </dt>
                  <dd class="route-view__sum">
                    {{ payable(payment.cashWithVat) }}
                  </dd>
                </template>
              </dl>
              <p class="panel-view__muted">
                {{ t("hangarPlanner.route.paymentHint") }}
              </p>
            </section>
            <p v-if="canSave" class="route-view__done">
              <i class="fa-light fa-circle-check" />
              {{ t("hangarPlanner.route.done", { ship: target.name }) }}
            </p>
            <Btn
              :type="BtnTypesEnum.SUBMIT"
              :size="BtnSizesEnum.MD"
              :loading="submitting"
              :disabled="!canSave"
              block
              data-test="hangar-plan-route-save"
            >
              <i class="fa-light fa-check" />
              {{ t("hangarPlanner.panel.saveRoute") }}
            </Btn>
          </aside>
        </div>
      </fieldset>
    </form>
  </div>
</template>

<style lang="scss" scoped src="../view.scss"></style>

<style lang="scss" scoped>
.route-view__fieldset {
  min-width: 0;
  margin: 0;
  padding: 0;
  border: 0;
}

.route-view {
  display: grid;
  grid-template-columns: minmax(0, 1fr) 270px;
  gap: 22px;
  align-items: start;
}

.route-view--stacked {
  grid-template-columns: minmax(0, 1fr);
}

.route-view__steps {
  display: flex;
  flex-direction: column;
  gap: 10px;
  min-width: 0;
}

.route-view__chain {
  display: flex;
  flex-direction: column;
  margin: 0;
  padding: 0;
  list-style: none;
}

.route-view__stop {
  display: flex;
  flex-wrap: wrap;
  gap: 10px 12px;
  align-items: center;
  justify-content: space-between;
  padding: 10px 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: var(--color-control);
}

.route-view__stop--done {
  border-color: var(--color-primary);
}

.route-view__stop-name {
  display: flex;
  flex-direction: column;
  gap: 2px;
  min-width: 0;

  strong {
    color: var(--color-lifted);
  }
}

.route-view__check {
  color: var(--color-success);
}

// The line a route runs along between its stops, with room for adding one.
.route-view__link {
  display: flex;
  gap: 10px;
  align-items: center;
  min-height: 26px;
  padding-left: 32px;

  &::before {
    content: "";
    align-self: stretch;
    width: 1px;
    background: var(--color-edge);
  }
}

.route-view__step {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 12px;
  border: 1px solid var(--color-edge-soft);
  border-radius: 12px;
  background: rgb(39 43 48 / 0.5);
}

.route-view__step-head {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
  align-items: center;
  justify-content: space-between;
}

// A line of its own, so each source keeps its whole label.
.route-view__sources {
  width: 100%;
}

.route-view__from {
  display: flex;
  gap: 8px;
  align-items: baseline;
  margin: 0;

  strong {
    color: var(--color-lifted);
  }

  i {
    color: var(--color-muted);
  }
}

.route-view__options {
  display: flex;
  flex-wrap: wrap;
  gap: 8px 12px;
  align-items: center;
}

.route-view__price {
  width: 160px;
  margin: 0;
}

.route-view__errors {
  margin: 0;
  padding-left: 18px;
}

.route-view__side {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.route-view__totals {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 6px 12px;
  margin: 0;

  dt {
    font-size: 0.84375rem;
    color: var(--color-text-dim);
  }

  dd {
    margin: 0;
    font-size: 0.84375rem;
    font-weight: 600;
    text-align: right;
    color: var(--color-lifted);
  }
}

.route-view__sum {
  padding-top: 6px;
  border-top: 1px solid var(--color-edge-faint);
}

.route-view__done {
  display: flex;
  gap: 6px;
  align-items: center;
  margin: 0;
  color: var(--color-success);
}
</style>
