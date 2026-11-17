import {
  AdditiveBlending,
  CanvasTexture,
  Color,
  Group,
  SRGBColorSpace,
  Sprite,
  SpriteMaterial,
  type Texture,
} from "three";

/**
 * The bodies of the starmap in the look the location pages give them: a
 * planet's or moon's surface by its type, in its colour, and a star as a
 * white-hot core running out into its colour inside a corona that breathes.
 * The pages draw them in CSS on a flat circle; here the same surfaces are
 * painted onto a texture that wraps a sphere, so a body turns and is lit from
 * its star.
 */
export type StarmapSurface = "rocky" | "gas" | "ice" | "cratered" | "city";

const WIDTH = 1024;
const HEIGHT = 512;

// Seeded from the body's slug, so a body looks the same on every visit and no
// two look alike.
const random = (seed: string) => {
  let state = 0;
  for (let index = 0; index < seed.length; index += 1) {
    state = (Math.imul(31, state) + seed.charCodeAt(index)) | 0;
  }

  return () => {
    state = (state + 0x6d2b79f5) | 0;
    let value = Math.imul(state ^ (state >>> 15), 1 | state);
    value ^= value + Math.imul(value ^ (value >>> 7), 61 | value);
    return ((value ^ (value >>> 14)) >>> 0) / 4294967296;
  };
};

// `color-mix(in srgb, color amount%, other)`, as the stylesheets mix them.
const mix = (color: string, amount: number, other: string) =>
  `#${new Color(other).lerp(new Color(color), amount).getHexString()}`;

const canvas = () => {
  const element = document.createElement("canvas");
  element.width = WIDTH;
  element.height = HEIGHT;
  return element;
};

// What is drawn once is drawn again a full turn either side, so the seam
// where the texture meets itself does not show.
const wrapped = (draw: (offset: number) => void) => {
  for (const offset of [-WIDTH, 0, WIDTH]) draw(offset);
};

// Long, ragged landmasses a shade darker than the ground, and lighter caps.
const paintRocky = (
  context: CanvasRenderingContext2D,
  color: string,
  next: () => number,
) => {
  context.fillStyle = mix(color, 0.84, "#000");
  context.filter = "blur(3px)";

  for (let count = 0; count < 7; count += 1) {
    const x = next() * WIDTH;
    const y = HEIGHT * (0.22 + next() * 0.56);
    const width = WIDTH * (0.06 + next() * 0.12);
    const height = HEIGHT * (0.05 + next() * 0.1);
    const points = 28;
    const shape = Array.from({ length: points }, () => 0.7 + next() * 0.45);

    wrapped((offset) => {
      context.beginPath();
      shape.forEach((scale, index) => {
        const angle = (index / points) * Math.PI * 2;
        const px = x + offset + Math.cos(angle) * width * scale;
        const py = y + Math.sin(angle) * height * scale;
        if (index === 0) context.moveTo(px, py);
        else context.lineTo(px, py);
      });
      context.closePath();
      context.fill();
    });
  }

  context.fillStyle = mix(color, 0.7, "#fff");
  context.globalAlpha = 0.45;

  for (const [edge, direction] of [
    [0, 1],
    [HEIGHT, -1],
  ]) {
    context.beginPath();
    context.moveTo(0, edge);
    for (let x = 0; x <= WIDTH; x += 16) {
      const depth = HEIGHT * (0.06 + Math.sin(x / 70 + next()) * 0.015);
      context.lineTo(x, edge + direction * depth);
    }
    context.lineTo(WIDTH, edge);
    context.closePath();
    context.fill();
  }

  context.globalAlpha = 1;
  context.filter = "none";
};

// Bands of the colour, lighter and darker, with a storm.
const paintBands = (
  context: CanvasRenderingContext2D,
  color: string,
  next: () => number,
) => {
  const bands: [string, number, number][] = [
    [mix(color, 0.8, "#fff"), 0, 0.12],
    [color, 0.12, 0.22],
    [mix(color, 0.78, "#000"), 0.22, 0.3],
    [mix(color, 0.85, "#fff"), 0.3, 0.41],
    [color, 0.41, 0.52],
    [mix(color, 0.72, "#000"), 0.52, 0.58],
    [mix(color, 0.88, "#fff"), 0.58, 0.71],
    [color, 0.71, 0.82],
    [mix(color, 0.8, "#000"), 0.82, 1],
  ];

  const phase = next() * Math.PI * 2;

  for (const [fill, from, to] of bands) {
    context.fillStyle = fill;
    context.beginPath();
    context.moveTo(0, from * HEIGHT);
    for (let x = 0; x <= WIDTH; x += 8) {
      const wave = Math.sin((x / WIDTH) * Math.PI * 6 + phase + from * 9) * 3;
      context.lineTo(x, from * HEIGHT + (from > 0 ? wave : 0));
    }
    for (let x = WIDTH; x >= 0; x -= 8) {
      const wave = Math.sin((x / WIDTH) * Math.PI * 6 + phase + to * 9) * 3;
      context.lineTo(x, to * HEIGHT + (to < 1 ? wave : 0) + 1);
    }
    context.closePath();
    context.fill();
  }

  const stormX = WIDTH * (0.15 + next() * 0.7);
  context.filter = "blur(4px)";
  context.fillStyle = mix(color, 0.55, "#fff");
  wrapped((offset) => {
    context.beginPath();
    context.ellipse(
      stormX + offset,
      HEIGHT * 0.62,
      WIDTH * 0.045,
      HEIGHT * 0.03,
      0,
      0,
      Math.PI * 2,
    );
    context.fill();
  });
  context.filter = "none";
};

// Pits lit the way a low sun lights them: the wall facing the light in
// shadow, the far wall catching it, the floor barely below the ground.
const paintCraters = (
  context: CanvasRenderingContext2D,
  color: string,
  next: () => number,
) => {
  const shadow = mix(color, 0.78, "#000");
  const rim = mix(color, 0.88, "#fff");
  const floor = mix(color, 0.92, "#000");
  context.filter = "blur(2px)";

  for (let count = 0; count < 46; count += 1) {
    const x = next() * WIDTH;
    const latitude = (next() - 0.5) * Math.PI * 0.8;
    const y = HEIGHT * (0.5 - latitude / Math.PI);
    const radius = HEIGHT * (0.012 + next() ** 2 * 0.05);
    // Wider towards the poles, so a crater stays round once wrapped.
    const stretch = 1 / Math.max(Math.cos(latitude), 0.3);
    const step = radius * 0.12;

    wrapped((offset) => {
      for (const [fill, dx, dy, scale] of [
        [shadow, -step, -step, 1.1],
        [rim, step, step, 1.1],
        [floor, 0, 0, 1],
      ] as const) {
        context.fillStyle = fill;
        context.beginPath();
        context.ellipse(
          x + offset + dx * stretch,
          y + dy,
          radius * scale * stretch,
          radius * scale,
          0,
          0,
          Math.PI * 2,
        );
        context.fill();
      }
    });
  }

  context.filter = "none";
};

// A planet covered by one city: a lattice of districts, about as many across
// the face as the location pages show.
const CITY_BLOCK = 24;

const paintCity = (context: CanvasRenderingContext2D, color: string) => {
  context.strokeStyle = mix(color, 0.8, "#000");
  context.lineWidth = 1.5;

  for (let x = 0; x <= WIDTH; x += CITY_BLOCK) {
    context.beginPath();
    context.moveTo(x, 0);
    context.lineTo(x, HEIGHT);
    context.stroke();
  }

  for (let y = 0; y <= HEIGHT; y += CITY_BLOCK) {
    context.beginPath();
    context.moveTo(0, y);
    context.lineTo(WIDTH, y);
    context.stroke();
  }
};

export const surfaceTexture = (
  surface: StarmapSurface,
  color: string,
  seed: string,
): Texture => {
  const element = canvas();
  const context = element.getContext("2d");

  if (context) {
    const next = random(seed);

    context.fillStyle = color;
    context.fillRect(0, 0, WIDTH, HEIGHT);

    if (surface === "rocky") paintRocky(context, color, next);
    if (surface === "gas") paintBands(context, color, next);
    if (surface === "cratered") paintCraters(context, color, next);
    if (surface === "city") paintCity(context, color);
    if (surface === "ice") {
      paintBands(context, color, next);
      // The same bands, washed out.
      context.globalAlpha = 0.4;
      context.fillStyle = color;
      context.fillRect(0, 0, WIDTH, HEIGHT);
      context.globalAlpha = 1;
    }
  }

  const texture = new CanvasTexture(element);
  texture.colorSpace = SRGBColorSpace;
  texture.anisotropy = 4;
  return texture;
};

const SUN_SIZE = 256;

const disc = (paint: (context: CanvasRenderingContext2D) => void) => {
  const element = document.createElement("canvas");
  element.width = SUN_SIZE;
  element.height = SUN_SIZE;
  const context = element.getContext("2d");
  if (context) paint(context);

  const texture = new CanvasTexture(element);
  texture.colorSpace = SRGBColorSpace;
  return texture;
};

const radial = (
  context: CanvasRenderingContext2D,
  stops: [number, string][],
) => {
  const half = SUN_SIZE / 2;
  const gradient = context.createRadialGradient(
    half,
    half,
    0,
    half,
    half,
    half,
  );
  for (const [at, color] of stops) gradient.addColorStop(at, color);
  context.fillStyle = gradient;
  context.fillRect(0, 0, SUN_SIZE, SUN_SIZE);
};

const alpha = (color: string, amount: number) => {
  const { r, g, b } = new Color(color);
  const channel = (value: number) => Math.round(value * 255);
  return `rgba(${channel(r)}, ${channel(g)}, ${channel(b)}, ${amount})`;
};

// How much larger the corona is than the core: the stylesheet insets it by
// 38%, and by 42% for a flare star.
const CORONA = 1.76;
const FLARE_CORONA = 1.84;

export interface StarmapSun {
  object: Group;
  // Breathes the corona and, for a flare star, flickers the core.
  animate: (seconds: number) => void;
  dispose: () => void;
}

/**
 * A star of radius one, facing the camera wherever it is: a core and a corona
 * behind it, as the location pages draw one.
 */
export const sun = (color: string, unstable: boolean): StarmapSun => {
  const coreTexture = disc((context) =>
    radial(context, [
      [0, "#ffffff"],
      [0.26, mix(color, 0.35, "#fff")],
      [0.62, color],
      [0.98, mix(color, 0.7, "#000")],
      [1, "rgba(0, 0, 0, 0)"],
    ]),
  );

  const coronaTexture = disc((context) => {
    if (unstable) {
      // A few uneven lobes around the glow.
      const half = SUN_SIZE / 2;
      const lobes: [number, number, number][] = [
        [0, 0.05, 0.38],
        [0.22, 0.25, 0.3],
        [0.5, 0.56, 0.4],
        [0.73, 0.76, 0.28],
      ];
      for (const [from, to, strength] of lobes) {
        context.fillStyle = alpha(color, strength);
        context.beginPath();
        context.moveTo(half, half);
        context.arc(
          half,
          half,
          half,
          from * Math.PI * 2 - Math.PI / 2,
          to * Math.PI * 2 - Math.PI / 2 + 0.25,
        );
        context.closePath();
        context.fill();
      }
      context.globalCompositeOperation = "destination-in";
      radial(context, [
        [0, "#000"],
        [0.34, "#000"],
        [1, "rgba(0, 0, 0, 0)"],
      ]);
      context.globalCompositeOperation = "source-over";
    }

    radial(context, [
      [0.28 / CORONA, alpha(color, 0.55)],
      [0.5, alpha(color, 0.18)],
      [0.7, alpha(color, 0)],
      [1, alpha(color, 0)],
    ]);
  });

  const core = new Sprite(
    new SpriteMaterial({ map: coreTexture, depthWrite: false }),
  );
  core.scale.setScalar(2);

  const coronaMaterial = new SpriteMaterial({
    map: coronaTexture,
    blending: AdditiveBlending,
    depthWrite: false,
    transparent: true,
  });
  const corona = new Sprite(coronaMaterial);
  const coronaScale = 2 * (unstable ? FLARE_CORONA : CORONA);
  corona.scale.setScalar(coronaScale);
  corona.renderOrder = -1;

  const object = new Group();
  object.add(corona, core);

  const animate = (seconds: number) => {
    if (unstable) {
      // Swells and turns a little, unevenly, every seven seconds.
      const phase = ((seconds % 7) / 7) * Math.PI * 2;
      const swell = Math.sin(phase) * 0.5 + Math.sin(phase * 2.3) * 0.5;
      coronaMaterial.opacity = 0.85 + swell * 0.15;
      coronaMaterial.rotation = Math.sin(phase) * 0.09;
      corona.scale.setScalar(coronaScale * (1.01 + swell * 0.05));
      const flicker =
        1 + Math.sin(seconds * 1.8) * Math.sin(seconds * 5.1) * 0.05;
      core.material.color.setScalar(flicker);
      return;
    }

    // From dim and small to full and large over four and a half seconds,
    // and back.
    const breath = (1 - Math.cos((seconds / 4.5) * Math.PI)) / 2;
    coronaMaterial.opacity = 0.55 + breath * 0.45;
    corona.scale.setScalar(coronaScale * (0.92 + breath * 0.14));
  };

  const dispose = () => {
    coreTexture.dispose();
    coronaTexture.dispose();
    core.material.dispose();
    coronaMaterial.dispose();
  };

  return { object, animate, dispose };
};
