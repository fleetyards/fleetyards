<script lang="ts">
export default {
  name: "ToolsPlaquePage",
};
</script>

<script lang="ts" setup>
import { useForm } from "vee-validate";
import { storeToRefs } from "pinia";
import { refDebounced } from "@vueuse/core";
import Heading from "@/shared/components/base/Heading/index.vue";
import { HeadingLevelEnum } from "@/shared/components/base/Heading/types";
import FormInput from "@/shared/components/base/FormInput/index.vue";
import Btn from "@/shared/components/base/Btn/index.vue";
import { BtnVariantsEnum } from "@/shared/components/base/Btn/types";
import ModelPickerSelect from "@/frontend/components/Models/PickerSelect/index.vue";
import VehiclePlaque from "@/frontend/components/Vehicles/Plaque/index.vue";
import PlaqueFields from "@/frontend/components/Vehicles/PlaqueFields/index.vue";
import PlaqueStylePicker from "@/frontend/components/Vehicles/PlaqueStylePicker/index.vue";
import PlaqueDownloadBtn from "@/frontend/components/Vehicles/PlaqueDownloadBtn/index.vue";
import { PLAQUE_LIMITS } from "@/frontend/components/Vehicles/PlaqueFields/rules";
import { plaqueMakerFor } from "@/frontend/components/Vehicles/Plaque/makers";
import { defaultPlaqueStyle } from "@/frontend/components/Vehicles/Plaque/styles";
import { ownerCaptain } from "@/frontend/components/Vehicles/Plaque/captain";
import {
  canSharePlaques,
  savesPlaquesByShare,
} from "@/frontend/components/Vehicles/Plaque/download";
import { type PlaqueContent } from "@/frontend/components/Vehicles/Plaque/types";
import { type PlaqueLines } from "@/frontend/components/Vehicles/PlaqueAttachModal/types";
import { useSessionStore } from "@/frontend/stores/session";
import { useRedirectBackStore } from "@/shared/stores/redirectBack";
import { useI18n } from "@/shared/composables/useI18n";
import { useComlink } from "@/shared/composables/useComlink";
import {
  useModel,
  type NullableVehicleOperationsGroupEnum,
  type VehiclePlaqueStyleEnum,
} from "@/services/fyApi";

const { t } = useI18n();
const comlink = useComlink();
const route = useRoute();
const router = useRouter();

const sessionStore = useSessionStore();
const { currentUser } = storeToRefs(sessionStore);

const isSupporter = computed(() => !!currentUser?.value?.supporter);

// The ship is in the address, so a link to the tool can bring one along.
const modelSlug = computed({
  get: () =>
    typeof route.query.model === "string" ? route.query.model : undefined,
  set: (slug) => {
    const { model: _model, ...query } = route.query;
    void router.replace({ query: slug ? { ...query, model: slug } : query });
  },
});

const { data: fetchedModel } = useModel(
  computed(() => modelSlug.value || ""),
  { query: { enabled: computed(() => !!modelSlug.value) } },
);

// Off the slug first: the query keeps its last answer after the ship is
// cleared.
const model = computed(() =>
  modelSlug.value ? fetchedModel.value : undefined,
);

const maker = computed(() =>
  model.value ? plaqueMakerFor({ model: model.value }) : undefined,
);

const { defineField, handleSubmit, values, setValues } = useForm({
  initialValues: {
    name: "",
    serial: "",
    dedication: "",
    dedicationVerse: "",
    launchedOn: null as string | null,
    launchPort: "",
    launchPortLocationId: null as string | null,
    affiliation: "",
    plaqueCaptain: "",
    operationsGroup: null as NullableVehicleOperationsGroupEnum | null,
  },
});

const [name] = defineField("name");
const [serial] = defineField("serial");
const [dedication] = defineField("dedication");
const [dedicationVerse] = defineField("dedicationVerse");
const [launchedOn] = defineField("launchedOn");
const [launchPort] = defineField("launchPort");
const [launchPortLocationId] = defineField("launchPortLocationId");
const [affiliation] = defineField("affiliation");
const [plaqueCaptain] = defineField("plaqueCaptain");
const [operationsGroup] = defineField("operationsGroup");

// Follows the ship until a style is picked by hand: a maker style for one
// maker is no style at all for the next.
const pickedStyle = ref<VehiclePlaqueStyleEnum>();

const plaqueStyle = computed<VehiclePlaqueStyleEnum>({
  get: () => {
    if (pickedStyle.value === "manufacturer" && !maker.value) {
      return defaultPlaqueStyle(isSupporter.value, maker.value);
    }

    return (
      pickedStyle.value ?? defaultPlaqueStyle(isSupporter.value, maker.value)
    );
  },
  set: (style) => {
    pickedStyle.value = style;
  },
});

// A signed-in visitor is named the way their public hangar names them.
const captain = computed(() => ownerCaptain(currentUser?.value));

const lines = computed<PlaqueLines>(() => ({
  dedication: dedication.value || null,
  dedicationVerse: dedicationVerse.value || null,
  launchedOn: launchedOn.value || null,
  launchPort: launchPort.value || null,
  launchPortLocationId: launchPortLocationId.value ?? null,
  affiliation: affiliation.value || null,
  plaqueCaptain: plaqueCaptain.value || null,
  operationsGroup: operationsGroup.value || null,
  plaqueStyle: plaqueStyle.value,
}));

const plaque = computed<PlaqueContent | undefined>(() => {
  if (!model.value) {
    return undefined;
  }

  const manufacturer = model.value.manufacturer;

  return {
    ...lines.value,
    id: `tool-${model.value.slug}`,
    name: name.value || undefined,
    serial: serial.value || undefined,
    model: model.value,
    manufacturerCode: manufacturer?.code,
    manufacturerShortName: manufacturer?.shortName || manufacturer?.name,
    shipyard: manufacturer?.shipyard,
  };
});

// The styles draw the plaque once each, all of them on screen at once; they
// catch up once typing pauses, so a keystroke redraws only the preview.
const stylesPlaque = refDebounced(plaque, 300);

const filename = computed(() =>
  ["plaque", model.value?.slug, serial.value].filter(Boolean).join("-"),
);

const shareTitle = computed(() =>
  t("title.vehiclePlaque", {
    vehicle: name.value || model.value?.name || "",
  }),
);

const canShare = canSharePlaques();
const canDownload = !savesPlaquesByShare();

// Signing in leaves the tool: the ship in the address brings it back to it,
// and what was written comes back from the tab's storage, once.
const redirectBackStore = useRedirectBackStore();

const DRAFT_KEY = "plaque-tool-draft";

const signIn = () => {
  redirectBackStore.setBackRoute(route.fullPath);

  try {
    sessionStorage.setItem(
      DRAFT_KEY,
      JSON.stringify({ values, style: pickedStyle.value }),
    );
  } catch {
    // Without storage the plaque is written again.
  }
};

onMounted(() => {
  try {
    const draft = sessionStorage.getItem(DRAFT_KEY);
    sessionStorage.removeItem(DRAFT_KEY);
    if (!draft) {
      return;
    }

    const { values: saved, style } = JSON.parse(draft);
    setValues(saved);
    pickedStyle.value = style;
  } catch {
    // A draft that cannot be read is dropped.
  }
});

// Submitted rather than only validated: a field shows its error once touched,
// and a submit touches them all, so a missing dedication says so.
const attach = handleSubmit(() => {
  if (!model.value) {
    return;
  }

  comlink.emit("open-modal", {
    component: () =>
      import("@/frontend/components/Vehicles/PlaqueAttachModal/index.vue"),
    props: { model: model.value, lines: lines.value, captain: captain.value },
  });
});
</script>

<template>
  <Heading hero>{{ t(`headlines.${route.meta.title}`) }}</Heading>

  <p class="plaque-tool__intro">{{ t("texts.plaqueTool.intro") }}</p>

  <div class="plaque-tool">
    <div class="plaque-tool__preview">
      <VehiclePlaque
        v-if="plaque"
        :vehicle="plaque"
        :captain="captain"
        data-test="plaque-tool-preview"
      />
      <p v-else class="plaque-tool__empty" data-test="plaque-tool-empty">
        <i class="fa-duotone fa-award" />
        {{ t("texts.plaqueTool.pickShip") }}
      </p>

      <div v-if="plaque" class="plaque-tool__actions">
        <PlaqueDownloadBtn
          v-if="canShare"
          :element="`vehicle-plaque-${plaque.id}`"
          :filename="filename"
          :share-title="shareTitle"
          share
          data-test="plaque-tool-share"
        />
        <PlaqueDownloadBtn
          v-if="canDownload"
          :element="`vehicle-plaque-${plaque.id}`"
          :filename="filename"
          :variant="canShare ? BtnVariantsEnum.GHOST : undefined"
          data-test="plaque-tool-download"
        />
        <Btn
          v-if="sessionStore.isAuthenticated"
          :variant="BtnVariantsEnum.GHOST"
          data-test="plaque-tool-attach"
          @click="attach"
        >
          <i class="fa-duotone fa-warehouse" />
          {{ t("actions.plaqueTool.attach") }}
        </Btn>
      </div>
      <p
        v-if="plaque && !sessionStore.isAuthenticated"
        class="plaque-tool__hint"
        data-test="plaque-tool-sign-in"
      >
        <router-link :to="{ name: 'login' }" @click="signIn">
          {{ t("texts.plaqueTool.signIn") }}
        </router-link>
      </p>
    </div>

    <form class="plaque-tool__form" @submit.prevent>
      <ModelPickerSelect
        v-model="modelSlug"
        name="plaqueModel"
        :label="t('labels.plaqueTool.ship')"
      />
      <div class="plaque-tool__names">
        <FormInput
          v-model="name"
          name="name"
          :label="t('labels.plaqueTool.name')"
          :rules="`max:${PLAQUE_LIMITS.line}`"
          :maxlength="PLAQUE_LIMITS.line"
          data-test="plaque-tool-name-input"
        />
        <FormInput
          v-model="serial"
          name="serial"
          :label="t('labels.vehiclePlaque.registry')"
          :rules="`max:${PLAQUE_LIMITS.line}`"
          :maxlength="PLAQUE_LIMITS.line"
        />
      </div>
      <PlaqueFields
        v-model:dedication="dedication"
        v-model:dedication-verse="dedicationVerse"
        v-model:launched-on="launchedOn"
        v-model:launch-port="launchPort"
        v-model:launch-port-location-id="launchPortLocationId"
        v-model:affiliation="affiliation"
        v-model:plaque-captain="plaqueCaptain"
        v-model:operations-group="operationsGroup"
        :captain-placeholder="captain"
        :captain-info="captain ? undefined : t('labels.plaqueTool.captainInfo')"
      />
    </form>
  </div>

  <template v-if="plaque">
    <Heading :level="HeadingLevelEnum.H2">
      {{ t("labels.vehiclePlaque.style") }}
    </Heading>
    <PlaqueStylePicker
      v-model="plaqueStyle"
      :vehicle="stylesPlaque ?? plaque"
      :captain="captain"
      :is-supporter="isSupporter"
    />
  </template>
</template>

<style lang="scss" scoped>
.plaque-tool__intro {
  max-width: 720px;
}

// The plaque beside the form, and above it where there is no room.
.plaque-tool {
  display: grid;
  grid-template-columns: minmax(0, 3fr) minmax(0, 2fr);
  gap: 32px;
  align-items: start;
  margin-bottom: 32px;

  @media (max-width: $tablet-breakpoint) {
    grid-template-columns: minmax(0, 1fr);
  }
}

.plaque-tool__preview {
  position: sticky;
  top: 16px;
  display: flex;
  flex-direction: column;
  gap: 16px;

  @media (max-width: $tablet-breakpoint) {
    position: static;
  }
}

.plaque-tool__empty {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
  margin: 0;
  padding: 64px 24px;
  border: 2px dashed var(--color-edge, rgb(122 130 136 / 0.5));
  border-radius: var(--radius-surface-slim, 12px);
  color: var(--color-text-dim);
  text-align: center;

  i {
    font-size: 2.4rem;
    color: var(--color-muted);
  }
}

.plaque-tool__actions {
  display: flex;
  flex-wrap: wrap;
  gap: 8px;
}

.plaque-tool__hint {
  margin: 0;
}

.plaque-tool__names {
  display: grid;
  grid-template-columns: repeat(2, minmax(0, 1fr));
  gap: 0 24px;
}
</style>
