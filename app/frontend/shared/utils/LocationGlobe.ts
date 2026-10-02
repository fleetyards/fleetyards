import type { CSSProperties } from "vue";

type Appearance = {
  color?: string | null;
  image?: { smallUrl?: string; url: string } | null;
};

// How a body's circle is filled: its picture where one was uploaded, else its
// colour shaded like a lit sphere, else nothing -- the circle keeps the plain
// fill its stylesheet gives it.
export const globeStyle = (
  appearance?: Appearance | null,
): CSSProperties | undefined => {
  const image = appearance?.image?.smallUrl ?? appearance?.image?.url;

  if (image) {
    return {
      backgroundImage: `url("${image}")`,
      backgroundSize: "cover",
      backgroundPosition: "center",
    };
  }

  const color = appearance?.color;

  if (!color) return undefined;

  return {
    backgroundImage: `radial-gradient(circle at 32% 28%, color-mix(in srgb, ${color} 55%, #fff) 0%, ${color} 38%, color-mix(in srgb, ${color} 40%, #000) 78%, color-mix(in srgb, ${color} 15%, #000) 100%)`,
  };
};
