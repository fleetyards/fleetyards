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

  // The lite export a full one falls back to when it will not decode: the
  // same pose, smaller enough to fit the decoder.
  const texturedHoloFallback = computed(() => {
    if (!texturedHoloExport.value || texturedHoloExport.value.lite) return;

    const lite = modelStateTexturedHolo(toValue(model), toValue(state), {
      lite: true,
    });

    return lite?.lite ? lite : undefined;
  });

  // Each export has an atlas of its own, so only its own maps fit it.
  const paintMaps = (
    paint: ModelPaint,
    lite = texturedHoloExport.value?.lite,
  ) =>
    lite
      ? {
          base: paint.media.holoTextureLite,
          orm: paint.media.holoTextureOrmLite,
          stencil: paint.media.holoTextureStencilLite,
        }
      : {
          base: paint.media.holoTexture,
          orm: paint.media.holoTextureOrm,
          stencil: paint.media.holoTextureStencil,
        };

  // A variant whose own colours are a livery of its base ship's wears it where
  // no paint is picked.
  const liveryMaps = (lite = texturedHoloExport.value?.lite) => {
    const { media } = toValue(model);

    return lite
      ? {
          base: media.holoTextureLite?.url,
          orm: media.holoTextureOrmLite?.url,
          stencil: media.holoTextureStencilLite?.url,
        }
      : {
          base: media.holoTexture?.url,
          orm: media.holoTextureOrm?.url,
          stencil: media.holoTextureStencil?.url,
        };
  };

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

    const mapsFor = (lite?: boolean) =>
      holoPaint.value ? paintMaps(holoPaint.value, lite) : liveryMaps(lite);

    const maps = textured ? mapsFor() : undefined;

    const fallbackMaps = textured ? mapsFor(true) : undefined;
    // A picked paint the lite atlas has no maps for would quietly come back
    // in the ship's own colours, under a picker still naming the paint.
    const fallbackFile =
      textured && (!holoPaint.value || fallbackMaps?.base)
        ? texturedHoloFallback.value?.file
        : undefined;

    return {
      path,
      length,
      size: holo?.size,
      textured,
      paint: maps?.base || undefined,
      paintOrm: maps?.orm || undefined,
      paintStencil: maps?.stencil || undefined,
      fallback: fallbackFile
        ? {
            path: fallbackFile.url,
            size: fallbackFile.size,
            paint: fallbackMaps?.base || undefined,
            paintOrm: fallbackMaps?.orm || undefined,
            paintStencil: fallbackMaps?.stencil || undefined,
          }
        : undefined,
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
