const SAMPLE_SIZE = 64;

// Channels are bucketed to 5 bits each, so gradients and JPEG noise land on the
// same colour instead of splitting its count across a hundred neighbours.
const BUCKET_SHIFT = 3;

type Bucket = { count: number; r: number; g: number; b: number };

const toHex = (value: number) =>
  Math.round(value).toString(16).padStart(2, "0");

const saturationAndLightness = (r: number, g: number, b: number) => {
  const max = Math.max(r, g, b) / 255;
  const min = Math.min(r, g, b) / 255;
  const lightness = (max + min) / 2;

  if (max === min) return { saturation: 0, lightness };

  const delta = max - min;
  const saturation =
    lightness > 0.5 ? delta / (2 - max - min) : delta / (max + min);

  return { saturation, lightness };
};

const distance = (a: Bucket, b: Bucket) =>
  Math.hypot(a.r - b.r, a.g - b.g, a.b - b.b);

/*
 * The colours an emblem is recognised by, most prominent first.
 *
 * Transparent pixels are the cut-out, and near-white, near-black and grey ones
 * are almost always outline, shading or background -- a squadron colour picked
 * from those would be the one colour the emblem does not have. Only when
 * nothing else is left do the greys count.
 */
export const keyColors = (
  data: Uint8ClampedArray,
  { limit = 3, minDistance = 60 } = {},
): string[] => {
  const vivid = new Map<number, Bucket>();
  const muted = new Map<number, Bucket>();

  for (let index = 0; index < data.length; index += 4) {
    const [r, g, b, a] = [
      data[index],
      data[index + 1],
      data[index + 2],
      data[index + 3],
    ];

    if (a < 128) continue;

    const { saturation, lightness } = saturationAndLightness(r, g, b);
    const target =
      saturation > 0.25 && lightness > 0.12 && lightness < 0.92 ? vivid : muted;

    const key =
      ((r >> BUCKET_SHIFT) << 10) |
      ((g >> BUCKET_SHIFT) << 5) |
      (b >> BUCKET_SHIFT);
    const bucket = target.get(key) ?? { count: 0, r: 0, g: 0, b: 0 };

    bucket.count += 1;
    bucket.r += r;
    bucket.g += g;
    bucket.b += b;
    target.set(key, bucket);
  }

  const source = vivid.size ? vivid : muted;

  const ranked = [...source.values()]
    .map((bucket) => ({
      count: bucket.count,
      r: bucket.r / bucket.count,
      g: bucket.g / bucket.count,
      b: bucket.b / bucket.count,
    }))
    .sort((left, right) => right.count - left.count);

  // Neighbouring buckets are the same colour to anybody looking, so a
  // suggestion has to differ visibly from every one ranked above it.
  const picked: Bucket[] = [];

  for (const candidate of ranked) {
    if (picked.length >= limit) break;
    if (picked.every((colour) => distance(colour, candidate) >= minDistance)) {
      picked.push(candidate);
    }
  }

  return picked.map(
    (colour) => `#${toHex(colour.r)}${toHex(colour.g)}${toHex(colour.b)}`,
  );
};

export const keyColorsFromFile = async (
  file: File,
  options?: Parameters<typeof keyColors>[1],
): Promise<string[]> => {
  const bitmap = await createImageBitmap(file);

  const scale = Math.min(
    1,
    SAMPLE_SIZE / Math.max(bitmap.width, bitmap.height),
  );
  const width = Math.max(1, Math.round(bitmap.width * scale));
  const height = Math.max(1, Math.round(bitmap.height * scale));

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;

  const context = canvas.getContext("2d");
  if (!context) return [];

  context.drawImage(bitmap, 0, 0, width, height);
  bitmap.close();

  return keyColors(context.getImageData(0, 0, width, height).data, options);
};
