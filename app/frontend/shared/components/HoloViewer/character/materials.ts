import {
  Color,
  DoubleSide,
  FrontSide,
  LinearSRGBColorSpace,
  type Material,
  MeshPhysicalMaterial,
  RepeatWrapping,
  MeshStandardMaterial,
  NoColorSpace,
  SRGBColorSpace,
  type Texture,
  TextureLoader,
} from "three";
import type { CharacterThreeMaterial, EyeRecipe, HeadRecipe } from "./types";

export const srgbToLinear = (c: number) =>
  c <= 0.04045 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4;

export const linearToSrgb = (c: number) => {
  const clamped = Math.min(Math.max(c, 0), 1);
  return clamped <= 0.0031308
    ? clamped * 12.92
    : 1.055 * clamped ** (1 / 2.4) - 0.055;
};

export const hexLinear = (hex: string) =>
  [1, 3, 5].map((i) => srgbToLinear(parseInt(hex.slice(i, i + 2), 16) / 255));

const YIQ = [
  [0.299, 0.587, 0.114],
  [0.596, -0.274, -0.322],
  [0.211, -0.523, 0.312],
];

const multiply = (a: number[][], b: number[][]) =>
  a.map((row) =>
    b[0].map((_, j) => row.reduce((sum, value, k) => sum + value * b[k][j], 0)),
  );

const invert = (m: number[][]) => {
  const [[a, b, c], [d, e, f], [g, h, i]] = m;
  const det = a * (e * i - f * h) - b * (d * i - f * g) + c * (d * h - e * g);
  return [
    [(e * i - f * h) / det, (c * h - b * i) / det, (b * f - c * e) / det],
    [(f * g - d * i) / det, (a * i - c * g) / det, (c * d - a * f) / det],
    [(d * h - e * g) / det, (b * g - a * h) / det, (a * e - b * d) / det],
  ];
};

// Turns sRGB values by a share of a full turn, in YIQ.
export const hueRotation = (turns: number) => {
  const angle = 2 * Math.PI * turns;
  const rotation = [
    [1, 0, 0],
    [0, Math.cos(angle), -Math.sin(angle)],
    [0, Math.sin(angle), Math.cos(angle)],
  ];
  return multiply(multiply(invert(YIQ), rotation), YIQ);
};

const clamp01 = (value: number) => Math.min(Math.max(value, 0), 1);

// One texel of each texture a recipe names, 0..1, alpha last.
export type Texels = (url: string) => number[] | undefined;

// A head recipe made ready to run over a million texels: its colours, hue
// turns and strengths worked out once, nothing allocated per texel.
export const headCompositor = (recipe: HeadRecipe) => {
  const gain = recipe.tone_gain;
  const steps = recipe.layers.map((layer) => {
    if (layer.type === "blemish") {
      return { layer, blemishes: [layer.freckles, layer.sunspots] };
    }
    if (layer.type === "makeup") {
      return {
        layer,
        tints: layer.channels.map((channel) => hexLinear(channel.color)),
      };
    }
    return {
      layer,
      rotation: hueRotation(layer.hue),
      strength: 1 - 0.5 * layer.age,
    };
  });
  const ink = [0, 0, 0];

  return (texels: Texels, out: number[]) => {
    const base = recipe.base ? texels(recipe.base) : undefined;
    let r = srgbToLinear(base?.[0] ?? 1) * gain[0];
    let g = srgbToLinear(base?.[1] ?? 1) * gain[1];
    let b = srgbToLinear(base?.[2] ?? 1) * gain[2];

    for (const step of steps) {
      const { layer } = step;
      if (layer.type === "blemish") {
        const mask = layer.mask ? texels(layer.mask) : undefined;
        const id = layer.id ? texels(layer.id) : undefined;
        if (!mask || !id) continue;
        for (const blemish of step.blemishes!) {
          const selected = id[blemish.channel] < blemish.amount ? 1 : 0;
          const a = clamp01(mask[blemish.channel] * selected * blemish.opacity);
          const f = 1 - a + a * blemish.darken;
          r *= f;
          g *= f;
          b *= f;
        }
      } else if (layer.type === "makeup") {
        const texture = layer.texture ? texels(layer.texture) : undefined;
        if (!texture) continue;
        layer.channels.forEach((channel, k) => {
          const a = clamp01(texture[k] * channel.opacity);
          const tint = step.tints![k];
          r = r * (1 - a) + tint[0] * a;
          g = g * (1 - a) + tint[1] * a;
          b = b * (1 - a) + tint[2] * a;
        });
      } else {
        const texture = layer.texture ? texels(layer.texture) : undefined;
        if (!texture) continue;
        const m = step.rotation!;
        for (let c = 0; c < 3; c++) {
          ink[c] = srgbToLinear(
            clamp01(
              m[c][0] * texture[0] +
                m[c][1] * texture[1] +
                m[c][2] * texture[2],
            ),
          );
        }
        const k = step.strength!;
        if (layer.blend === "multiply") {
          r *= 1 - k + k * ink[0];
          g *= 1 - k + k * ink[1];
          b *= 1 - k + k * ink[2];
        } else {
          const a = (texture[3] ?? 1) * k;
          r = r * (1 - a) + ink[0] * a;
          g = g * (1 - a) + ink[1] * a;
          b = b * (1 - a) + ink[2] * a;
        }
      }
    }

    out[0] = linearToSrgb(r);
    out[1] = linearToSrgb(g);
    out[2] = linearToSrgb(b);
  };
};

// The head's base colour at one texel, in sRGB: the skin set tinted to the
// character's tone, then freckles and sun spots, makeup and the tattoo.
export const compositeHeadTexel = (recipe: HeadRecipe, texels: Texels) => {
  const out = [0, 0, 0];
  headCompositor(recipe)(texels, out);
  return out;
};

// The eye's colour at one texel, in sRGB: the customizer's white iris tinted
// to the character's eye colour over the sclera.
export const compositeEyeTexel = (recipe: EyeRecipe, iris: number[]) => {
  const sclera = hexLinear(recipe.sclera);
  const tint = hexLinear(recipe.iris_color);
  const a = iris[3] ?? 1;
  return [0, 1, 2].map((c) =>
    linearToSrgb(
      sclera[c] * (1 - a) + clamp01(srgbToLinear(iris[c]) * tint[c] * 1.6) * a,
    ),
  );
};

const loader = new TextureLoader();
loader.setCrossOrigin("anonymous");

const textures = new Map<string, Promise<Texture>>();

// glTF texture space, which three's loader would otherwise flip.
export const loadTexture = (url: string, colorSpace: string = NoColorSpace) => {
  const key = `${url}|${colorSpace}`;
  let loading = textures.get(key);
  if (!loading) {
    loading = loader.loadAsync(url).then((texture) => {
      texture.flipY = false;
      texture.colorSpace = colorSpace;
      return texture;
    });
    loading.catch(() => textures.delete(key));
    textures.set(key, loading);
  }
  return loading;
};

const loadImage = (url: string) =>
  new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image();
    image.crossOrigin = "anonymous";
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = url;
  });

// Every image a recipe names, drawn at one size so a texel lines up across
// them, as RGBA bytes.
const pixels = async (urls: string[], size: number) => {
  const canvas = document.createElement("canvas");
  canvas.width = size;
  canvas.height = size;
  const context = canvas.getContext("2d", { willReadFrequently: true });
  if (!context) throw new Error("no 2d canvas");

  const entries = await Promise.all(
    [...new Set(urls)].map(async (url) => {
      const image = await loadImage(url);
      context.clearRect(0, 0, size, size);
      context.drawImage(image, 0, 0, size, size);
      return [url, context.getImageData(0, 0, size, size).data] as const;
    }),
  );
  return { canvas, context, images: new Map(entries) };
};

// Rows between yields, so a bake never holds the page for long.
const BAKE_ROWS = 64;

const bake = async (
  urls: string[],
  size: number,
  texel: (texels: Texels, out: number[]) => void,
) => {
  const { canvas, context, images } = await pixels(urls, size);
  const out = context.createImageData(size, size);
  const sources = [...images.entries()].map(([url, data]) => ({
    url,
    data,
    texel: [0, 0, 0, 0],
  }));
  const byUrl = new Map(sources.map((source) => [source.url, source.texel]));
  const texels: Texels = (url) => byUrl.get(url);
  const colour = [0, 0, 0];

  for (let row = 0; row < size; row += BAKE_ROWS) {
    const end = Math.min(size, row + BAKE_ROWS) * size;
    for (let p = row * size; p < end; p++) {
      for (const source of sources) {
        const i = p * 4;
        source.texel[0] = source.data[i] / 255;
        source.texel[1] = source.data[i + 1] / 255;
        source.texel[2] = source.data[i + 2] / 255;
        source.texel[3] = source.data[i + 3] / 255;
      }
      texel(texels, colour);
      out.data[p * 4] = Math.round(colour[0] * 255);
      out.data[p * 4 + 1] = Math.round(colour[1] * 255);
      out.data[p * 4 + 2] = Math.round(colour[2] * 255);
      out.data[p * 4 + 3] = 255;
    }
    await new Promise((resolve) => setTimeout(resolve, 0));
  }

  context.putImageData(out, 0, 0);
  return canvas;
};

export const HEAD_SIZE = 1024;
export const EYE_SIZE = 512;

const headUrls = (recipe: HeadRecipe) =>
  [
    recipe.base,
    ...recipe.layers.flatMap((layer) =>
      layer.type === "blemish" ? [layer.mask, layer.id] : [layer.texture],
    ),
  ].filter((url): url is string => !!url);

export const bakeHead = (recipe: HeadRecipe) =>
  bake(headUrls(recipe), HEAD_SIZE, headCompositor(recipe));

export const bakeEyes = (recipe: EyeRecipe) =>
  recipe.iris
    ? bake([recipe.iris], EYE_SIZE, (texels, out) => {
        const [r, g, b] = compositeEyeTexel(
          recipe,
          texels(recipe.iris!) ?? [1, 1, 1, 0],
        );
        out[0] = r;
        out[1] = g;
        out[2] = b;
      })
    : Promise.resolve(undefined);

// A three.js material for one accessory sub-material; the strand variation
// multiplies the colour by an ID map.
// Textures a material made for itself, freed with it. Not in userData, which
// three copies through JSON when it clones a material.
export const ownedTextures = new WeakMap<Material, Texture[]>();

// Strand textures repeat: some cards run past u = 1. A copy carries the
// wrapping, as the loaded texture is shared, and is the material's to free.
const repeating = (texture?: Texture) => {
  if (!texture) return texture;
  const copy = texture.clone();
  copy.wrapS = RepeatWrapping;
  copy.wrapT = RepeatWrapping;
  copy.needsUpdate = true;
  return copy;
};

// A three.js material for one accessory sub-material, as the export resolves
// it. Strand cards keep their opacity as the texture is minified, as the
// game's OpacityMipScale does: without it the mostly empty strand atlas
// averages away in the lower mip levels and the cards vanish under the alpha
// test. The strand variation multiplies the colour by an ID map.
export const characterMaterial = async (
  three: CharacterThreeMaterial,
  variation?: { map: string | null; amount: number },
  occlusion = 1,
) => {
  const [map, loadedAlpha, loadedIds] = await Promise.all([
    three.map
      ? loadTexture(three.map, SRGBColorSpace).catch(() => undefined)
      : undefined,
    three.alphaMap
      ? loadTexture(three.alphaMap).catch(() => undefined)
      : undefined,
    variation?.map && variation.amount
      ? loadTexture(variation.map).catch(() => undefined)
      : undefined,
  ]);
  const alphaMap = repeating(loadedAlpha);
  const idMap = repeating(loadedIds);

  const parameters = {
    color: three.color
      ? new Color().setRGB(
          three.color[0],
          three.color[1],
          three.color[2],
          LinearSRGBColorSpace,
        )
      : undefined,
    map: map ?? null,
    alphaMap: alphaMap ?? null,
    alphaTest: three.alphaTest ?? 0,
    alphaToCoverage: !!three.alphaToCoverage,
    transparent: !!three.transparent,
    depthWrite: three.depthWrite ?? true,
    opacity: three.opacity ?? 1,
    side: three.side === "DoubleSide" ? DoubleSide : FrontSide,
    roughness: three.roughness ?? 1,
    metalness: three.metalness ?? 0,
    polygonOffset: !!three.polygonOffset,
    polygonOffsetFactor: three.polygonOffsetFactor ?? 0,
  };
  const material =
    three.type === "MeshPhysicalMaterial"
      ? new MeshPhysicalMaterial({
          ...parameters,
          specularIntensity: three.specularIntensity ?? 1,
          specularColor: three.specularColor
            ? new Color().setRGB(
                three.specularColor[0],
                three.specularColor[1],
                three.specularColor[2],
                LinearSRGBColorSpace,
              )
            : new Color(1, 1, 1),
        })
      : new MeshStandardMaterial(parameters);

  const mipScale = alphaMap ? (three.alphaMipScale ?? 0) : 0;
  const varied = !!(idMap && variation);

  const occluded = occlusion < 1;

  if (mipScale || varied || occluded) {
    material.onBeforeCompile = (shader) => {
      let uniforms = "";
      if (mipScale) {
        shader.uniforms.alphaMipScale = { value: mipScale };
        uniforms += "uniform float alphaMipScale;\n";
        shader.fragmentShader = shader.fragmentShader.replace(
          "#include <alphamap_fragment>",
          `#ifdef USE_ALPHAMAP
  vec2 alphaTexels = vec2(textureSize(alphaMap, 0));
  vec2 alphaDx = dFdx(vAlphaMapUv * alphaTexels);
  vec2 alphaDy = dFdy(vAlphaMapUv * alphaTexels);
  float alphaLod = max(0.0, 0.5 * log2(max(dot(alphaDx, alphaDx), dot(alphaDy, alphaDy))));
  diffuseColor.a *= clamp(texture2D(alphaMap, vAlphaMapUv).g * (1.0 + alphaLod * alphaMipScale), 0.0, 1.0);
#endif`,
        );
      }
      if (varied) {
        shader.uniforms.strandIds = { value: idMap };
        shader.uniforms.strandVariation = { value: variation!.amount };
        uniforms +=
          "uniform sampler2D strandIds;\nuniform float strandVariation;\nvarying vec2 vStrandUv;\n";
        shader.fragmentShader = shader.fragmentShader.replace(
          "#include <map_fragment>",
          "#include <map_fragment>\ndiffuseColor.rgb *= 1.0 + strandVariation * (texture2D(strandIds, vStrandUv).r - 0.5);",
        );
        shader.vertexShader = shader.vertexShader
          .replace(
            "#include <common>",
            "#include <common>\nvarying vec2 vStrandUv;",
          )
          .replace(
            "#include <uv_vertex>",
            "#include <uv_vertex>\nvStrandUv = uv;",
          );
      }
      if (occluded) {
        shader.uniforms.hairOcclusion = { value: occlusion };
        uniforms += "uniform float hairOcclusion;\n";
        shader.fragmentShader = shader.fragmentShader.replace(
          "#include <aomap_fragment>",
          `reflectedLight.indirectDiffuse *= hairOcclusion;
reflectedLight.indirectSpecular *= hairOcclusion;
reflectedLight.directDiffuse *= hairOcclusion;
#include <aomap_fragment>`,
        );
      }
      shader.fragmentShader = shader.fragmentShader.replace(
        "#include <common>",
        `#include <common>\n${uniforms}`,
      );
    };
    material.customProgramCacheKey = () =>
      `character-strands-${mipScale ? 1 : 0}-${varied ? 1 : 0}-${occluded ? 1 : 0}`;
  }

  ownedTextures.set(
    material,
    [alphaMap, idMap].filter((texture): texture is Texture => !!texture),
  );

  return material;
};
