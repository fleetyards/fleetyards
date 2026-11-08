import {
  Color,
  DoubleSide,
  FrontSide,
  LinearSRGBColorSpace,
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

// The head's base colour at one texel, in sRGB: the skin set tinted to the
// character's tone, then freckles and sun spots, makeup and the tattoo.
export const compositeHeadTexel = (recipe: HeadRecipe, texels: Texels) => {
  const base = recipe.base ? texels(recipe.base) : undefined;
  let color = [0, 1, 2].map(
    (c) => srgbToLinear(base?.[c] ?? 1) * recipe.tone_gain[c],
  );

  recipe.layers.forEach((layer) => {
    if (layer.type === "blemish") {
      const mask = layer.mask ? texels(layer.mask) : undefined;
      const id = layer.id ? texels(layer.id) : undefined;
      if (!mask || !id) return;
      [layer.freckles, layer.sunspots].forEach((blemish) => {
        const selected = id[blemish.channel] < blemish.amount ? 1 : 0;
        const a = clamp01(mask[blemish.channel] * selected * blemish.opacity);
        color = color.map((c) => c * (1 - a + a * blemish.darken));
      });
    } else if (layer.type === "makeup") {
      const texture = layer.texture ? texels(layer.texture) : undefined;
      if (!texture) return;
      layer.channels.forEach((channel, k) => {
        const a = clamp01(texture[k] * channel.opacity);
        const tint = hexLinear(channel.color);
        color = color.map((c, i) => c * (1 - a) + tint[i] * a);
      });
    } else if (layer.type === "tattoo") {
      const texture = layer.texture ? texels(layer.texture) : undefined;
      if (!texture) return;
      const rotation = hueRotation(layer.hue);
      const ink = rotation.map((row) =>
        srgbToLinear(
          clamp01(
            row[0] * texture[0] + row[1] * texture[1] + row[2] * texture[2],
          ),
        ),
      );
      const k = 1 - 0.5 * layer.age;
      if (layer.blend === "multiply") {
        color = color.map((c, i) => c * (1 - k + k * ink[i]));
      } else {
        const a = (texture[3] ?? 1) * k;
        color = color.map((c, i) => c * (1 - a) + ink[i] * a);
      }
    }
  });

  return color.map(linearToSrgb);
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

const bake = async (
  urls: string[],
  size: number,
  texel: (texels: Texels) => number[],
) => {
  const { canvas, context, images } = await pixels(urls, size);
  const out = context.createImageData(size, size);
  const sample = new Map<string, number[]>(
    [...images.keys()].map((url) => [url, [0, 0, 0, 0]]),
  );
  const texels: Texels = (url) => sample.get(url);

  for (let p = 0; p < size * size; p++) {
    images.forEach((data, url) => {
      const texel = sample.get(url)!;
      for (let c = 0; c < 4; c++) texel[c] = data[p * 4 + c] / 255;
    });
    const [r, g, b] = texel(texels);
    out.data[p * 4] = Math.round(r * 255);
    out.data[p * 4 + 1] = Math.round(g * 255);
    out.data[p * 4 + 2] = Math.round(b * 255);
    out.data[p * 4 + 3] = 255;
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
  bake(headUrls(recipe), HEAD_SIZE, (texels) =>
    compositeHeadTexel(recipe, texels),
  );

export const bakeEyes = (recipe: EyeRecipe) =>
  recipe.iris
    ? bake([recipe.iris], EYE_SIZE, (texels) =>
        compositeEyeTexel(recipe, texels(recipe.iris!) ?? [1, 1, 1, 0]),
      )
    : Promise.resolve(undefined);

// A three.js material for one accessory sub-material; the strand variation
// multiplies the colour by an ID map.
export const characterMaterial = async (
  three: CharacterThreeMaterial,
  variation?: { map: string | null; amount: number },
) => {
  const [map, alphaMap, idMap] = await Promise.all([
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

  const material = new MeshStandardMaterial({
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
    transparent: !!three.transparent,
    depthWrite: three.depthWrite ?? true,
    opacity: three.opacity ?? 1,
    side: three.side === "DoubleSide" ? DoubleSide : FrontSide,
    roughness: three.roughness ?? 1,
    metalness: three.metalness ?? 0,
    polygonOffset: !!three.polygonOffset,
    polygonOffsetFactor: three.polygonOffsetFactor ?? 0,
  });

  if (idMap && variation) {
    material.onBeforeCompile = (shader) => {
      shader.uniforms.strandIds = { value: idMap };
      shader.uniforms.strandVariation = { value: variation.amount };
      shader.fragmentShader = shader.fragmentShader
        .replace(
          "#include <common>",
          "#include <common>\nuniform sampler2D strandIds;\nuniform float strandVariation;",
        )
        .replace(
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
      shader.fragmentShader = shader.fragmentShader.replace(
        "#include <common>",
        "#include <common>\nvarying vec2 vStrandUv;",
      );
    };
    material.customProgramCacheKey = () => "character-strands";
  }

  return material;
};
