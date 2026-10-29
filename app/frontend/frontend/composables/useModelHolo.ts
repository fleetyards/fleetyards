import {
  FeatureFlagName,
  type Model,
  type ModelPaint,
  useModelPaints,
} from "@/services/fyApi";
import { useFeatures } from "@/frontend/composables/useFeatures";
import {
  type ModelStateEnum,
  modelStateHolo,
  modelStateMetrics,
  modelStateTexturedHolo,
} from "@/frontend/composables/useModelStates";
import { isLowPowerDevice } from "@/shared/composables/useLowPowerDevice";

type Options = {
  textured?: boolean;
  paintId?: string;
};

// The holo a ship is shown by in a state: the plain one, or the textured
// export in the ship's own colours or one of its paints.
export const useModelHolo = (
  model: MaybeRefOrGetter<Model>,
  state: MaybeRefOrGetter<ModelStateEnum>,
  options: Options = {},
) => {
  const { isFeatureEnabled } = useFeatures();

  // Decided once: `lowPower` follows the window width, and a resize across the
  // breakpoint should change the render settings, not download the other file.
  const preferLiteHolo = isLowPowerDevice();

  const texturedHolo = ref(options.textured ?? false);

  // A state without a painted export of its own leaves the switch out rather
  // than offering a button that changes nothing.
  const texturedHoloExport = computed(() =>
    isFeatureEnabled(FeatureFlagName.HOLO_TEXTURED)
      ? modelStateTexturedHolo(toValue(model), toValue(state), {
          lite: preferLiteHolo,
        })
      : undefined,
  );

  const texturedHoloAvailable = computed(() => !!texturedHoloExport.value);

  const toggleTexturedHolo = () => {
    texturedHolo.value = !texturedHolo.value;
  };

  // The paints the textured holo can be repainted in, beside the ship's own,
  // fetched once the switch is on: most visitors never turn it.
  const { data: paints } = useModelPaints(() => toValue(model).slug, {
    query: {
      enabled: computed(
        () => texturedHoloAvailable.value && texturedHolo.value,
      ),
    },
  });

  // Each export has an atlas of its own, so only its own maps fit it.
  const paintMaps = (paint: ModelPaint) =>
    texturedHoloExport.value?.lite
      ? {
          base: paint.media.holoTextureLite,
          orm: paint.media.holoTextureOrmLite,
        }
      : { base: paint.media.holoTexture, orm: paint.media.holoTextureOrm };

  // A variant whose own colours are a livery of its base ship's wears it where
  // no paint is picked.
  const liveryMaps = computed(() => {
    const { media } = toValue(model);

    return texturedHoloExport.value?.lite
      ? { base: media.holoTextureLite?.url, orm: media.holoTextureOrmLite?.url }
      : { base: media.holoTexture?.url, orm: media.holoTextureOrm?.url };
  });

  const holoPaints = computed(() =>
    (paints.value ?? []).filter((paint) => !!paintMaps(paint).base),
  );

  const holoPaintId = ref<string | undefined>(options.paintId);

  const holoPaint = computed(() =>
    holoPaints.value.find((paint) => paint.id === holoPaintId.value),
  );

  const holoModel = computed(() => {
    const current = toValue(model);
    const currentState = toValue(state);
    const textured = texturedHoloAvailable.value && texturedHolo.value;
    const holo = textured
      ? texturedHoloExport.value?.file
      : modelStateHolo(current, currentState, { lite: preferLiteHolo });
    const path = holo?.url;
    const length = modelStateMetrics(current, currentState).fleetchartLength;

    if (!path || !length) {
      return;
    }

    const maps = textured
      ? holoPaint.value
        ? paintMaps(holoPaint.value)
        : liveryMaps.value
      : undefined;

    return {
      path,
      length,
      size: holo?.size,
      textured,
      paint: maps?.base || undefined,
      paintOrm: maps?.orm || undefined,
    };
  });

  return {
    texturedHolo,
    texturedHoloAvailable,
    toggleTexturedHolo,
    holoPaints,
    holoPaintId,
    holoPaint,
    holoModel,
  };
};
