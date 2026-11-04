import {
  BackSide,
  BoxGeometry,
  Data3DTexture,
  LinearFilter,
  Mesh,
  RedFormat,
  RepeatWrapping,
  ShaderMaterial,
  type Texture,
} from "three";

const NOISE_SIZE = 64;
const NOISE_PERIODS = [8, 16];

const seededRandom = (seed: number) => () => {
  seed = (seed + 0x6d2b79f5) | 0;
  let mixed = Math.imul(seed ^ (seed >>> 15), 1 | seed);
  mixed = (mixed + Math.imul(mixed ^ (mixed >>> 7), 61 | mixed)) ^ mixed;
  return ((mixed ^ (mixed >>> 14)) >>> 0) / 4294967296;
};

const fade = (t: number) => t * t * t * (t * (t * 6 - 15) + 10);

// Perlin noise on a lattice that wraps, so the volume tiles without a seam.
const latticeNoise = (period: number, random: () => number) => {
  const gradients = new Float32Array(period ** 3 * 3);

  for (let i = 0; i < gradients.length; i += 3) {
    const z = random() * 2 - 1;
    const angle = random() * Math.PI * 2;
    const radius = Math.sqrt(1 - z * z);
    gradients[i] = radius * Math.cos(angle);
    gradients[i + 1] = radius * Math.sin(angle);
    gradients[i + 2] = z;
  }

  const corner = (
    x: number,
    y: number,
    z: number,
    dx: number,
    dy: number,
    dz: number,
  ) => {
    const index =
      (((x % period) + (y % period) * period + (z % period) * period * period) *
        3) |
      0;

    return (
      gradients[index] * dx +
      gradients[index + 1] * dy +
      gradients[index + 2] * dz
    );
  };

  const lerp = (a: number, b: number, t: number) => a + (b - a) * t;

  return (u: number, v: number, w: number) => {
    const px = u * period;
    const py = v * period;
    const pz = w * period;
    const x = Math.floor(px);
    const y = Math.floor(py);
    const z = Math.floor(pz);
    const dx = px - x;
    const dy = py - y;
    const dz = pz - z;
    const fx = fade(dx);
    const fy = fade(dy);
    const fz = fade(dz);

    return lerp(
      lerp(
        lerp(
          corner(x, y, z, dx, dy, dz),
          corner(x + 1, y, z, dx - 1, dy, dz),
          fx,
        ),
        lerp(
          corner(x, y + 1, z, dx, dy - 1, dz),
          corner(x + 1, y + 1, z, dx - 1, dy - 1, dz),
          fx,
        ),
        fy,
      ),
      lerp(
        lerp(
          corner(x, y, z + 1, dx, dy, dz - 1),
          corner(x + 1, y, z + 1, dx - 1, dy, dz - 1),
          fx,
        ),
        lerp(
          corner(x, y + 1, z + 1, dx, dy - 1, dz - 1),
          corner(x + 1, y + 1, z + 1, dx - 1, dy - 1, dz - 1),
          fx,
        ),
        fy,
      ),
      fz,
    );
  };
};

let noiseVoxels: Uint8Array<ArrayBuffer> | undefined;

export const skyNoiseVoxels = () => {
  if (noiseVoxels) return noiseVoxels;

  const random = seededRandom(1);
  const layers = NOISE_PERIODS.map((period) => latticeNoise(period, random));
  const voxels = new Uint8Array(NOISE_SIZE ** 3);

  let index = 0;
  for (let z = 0; z < NOISE_SIZE; z += 1) {
    for (let y = 0; y < NOISE_SIZE; y += 1) {
      for (let x = 0; x < NOISE_SIZE; x += 1) {
        const value = layers.reduce(
          (sum, layer, octave) =>
            sum +
            layer(x / NOISE_SIZE, y / NOISE_SIZE, z / NOISE_SIZE) / 2 ** octave,
          0,
        );
        voxels[index] = Math.max(0, Math.min(255, 127.5 + value * 215));
        index += 1;
      }
    }
  }

  noiseVoxels = voxels;

  return voxels;
};

const buildNoiseTexture = () => {
  const texture = new Data3DTexture(
    skyNoiseVoxels(),
    NOISE_SIZE,
    NOISE_SIZE,
    NOISE_SIZE,
  );
  texture.format = RedFormat;
  texture.minFilter = LinearFilter;
  texture.magFilter = LinearFilter;
  texture.wrapS = RepeatWrapping;
  texture.wrapT = RepeatWrapping;
  texture.wrapR = RepeatWrapping;
  texture.unpackAlignment = 1;
  texture.needsUpdate = true;

  return texture;
};

const vertexShader = /* glsl */ `
  varying vec3 vDirection;

  void main() {
    vDirection = position;
    vec4 clip = projectionMatrix * mat4(mat3(viewMatrix)) * vec4(position, 1.0);
    gl_Position = clip.xyww;
  }
`;

const fragmentShader = /* glsl */ `
  uniform sampler2D panorama;
  uniform sampler3D noise;

  varying vec3 vDirection;

  #include <common>

  // Blurred past the panorama's own compression and its stars, which at this
  // camera's narrow view would each cover several screen pixels.
  const int PANORAMA_LOD = 1;

  const mat3 OCTAVE_TURN = mat3(
     0.00,  0.80,  0.60,
    -0.80,  0.36, -0.48,
    -0.60, -0.48,  0.64
  );

  float fbm(vec3 point, int octaves) {
    float sum = 0.0;
    float weight = 0.5;
    float total = 0.0;

    for (int octave = 0; octave < octaves; octave++) {
      sum += weight * texture(noise, point).r;
      total += weight;
      weight *= 0.5;
      point = OCTAVE_TURN * point * 2.03;
    }

    return sum / total;
  }

  // Four bilinear taps for a B-spline: stretched this far a plain bilinear
  // lookup shows its grid as diamonds.
  vec4 smoothPanorama(vec2 uv) {
    vec2 size = vec2(textureSize(panorama, PANORAMA_LOD));
    vec2 texel = uv * size - 0.5;
    vec2 cell = floor(texel);
    vec2 f = texel - cell;
    vec2 f2 = f * f;
    vec2 f3 = f2 * f;

    vec2 w0 = (1.0 - 3.0 * f + 3.0 * f2 - f3) / 6.0;
    vec2 w1 = (4.0 - 6.0 * f2 + 3.0 * f3) / 6.0;
    vec2 w2 = (1.0 + 3.0 * f + 3.0 * f2 - 3.0 * f3) / 6.0;
    vec2 w3 = f3 / 6.0;

    vec2 g0 = w0 + w1;
    vec2 g1 = w2 + w3;
    vec2 low = (cell - 0.5 + w1 / g0) / size;
    vec2 high = (cell + 1.5 + w3 / g1) / size;

    return (
      textureLod(panorama, vec2(low.x, low.y), float(PANORAMA_LOD)) * g0.x * g0.y +
      textureLod(panorama, vec2(high.x, low.y), float(PANORAMA_LOD)) * g1.x * g0.y +
      textureLod(panorama, vec2(low.x, high.y), float(PANORAMA_LOD)) * g0.x * g1.y +
      textureLod(panorama, vec2(high.x, high.y), float(PANORAMA_LOD)) * g1.x * g1.y
    );
  }

  void main() {
    vec3 direction = normalize(vDirection);

    vec3 warp = vec3(
      fbm(direction * 1.1, 4),
      fbm(direction * 1.1 + 17.3, 4),
      fbm(direction * 1.1 + 41.7, 4)
    ) - 0.5;
    vec3 warped = normalize(direction + warp * 0.09);

    vec3 sky = smoothPanorama(equirectUv(warped)).rgb;

    float gas = fbm(warped * 0.9 + warp * 0.35 + 5.0, 6);
    float detail = mix(0.62, 1.38, smoothstep(0.24, 0.76, gas));

    // Brightening past full would clip one channel first and shift the hue.
    float peak = max(sky.r, max(sky.g, sky.b));
    detail = mix(detail, min(detail, 1.0), smoothstep(0.4, 1.0, peak));


    gl_FragColor = vec4(sky * detail, 1.0);

    #include <colorspace_fragment>

    // The skies are mostly near black, where eight bits would show as bands.
    float dither = fract(
      52.9829189 * fract(dot(gl_FragCoord.xy, vec2(0.06711056, 0.00583715)))
    );
    gl_FragColor.rgb += (dither - 0.5) / 255.0;
  }
`;

export const buildSky = (panorama: Texture) => {
  const noise = buildNoiseTexture();
  const material = new ShaderMaterial({
    uniforms: {
      panorama: { value: panorama },
      noise: { value: noise },
    },
    vertexShader,
    fragmentShader,
    side: BackSide,
    depthTest: false,
    depthWrite: false,
    toneMapped: false,
  });

  const sky = new Mesh(new BoxGeometry(1, 1, 1), material);
  sky.name = "sky";
  sky.renderOrder = -1000;
  sky.frustumCulled = false;
  sky.raycast = () => {};

  return sky;
};

export const disposeSky = (sky: ReturnType<typeof buildSky>) => {
  sky.geometry.dispose();
  sky.material.uniforms.noise.value.dispose();
  sky.material.dispose();
};
