import domtoimage from "dom-to-image";
import downloadJs from "downloadjs";
import { toDataUrl } from "./dataUrl";
import { plaqueFontFaces, withFontFaces } from "./fonts";

// Drawn at three times its size on screen, so a download stays sharp.
const SCALE = 3;

// The size platforms show a large link preview at.
const PREVIEW_WIDTH = 1200;
const PREVIEW_HEIGHT = 630;
const PREVIEW_PADDING = 36;
const PREVIEW_BACKGROUND = "#0d0f12";

const urlOf = (value: string) => value.match(/url\(["']?([^"')]+)["']?\)/)?.[1];

const loadImage = (src: string) =>
  new Promise<HTMLImageElement>((resolve, reject) => {
    const image = new Image();
    image.onload = () => resolve(image);
    image.onerror = reject;
    image.src = src;
  });

// The plaque is drawn with clip-paths, masks and conic gradients that a canvas
// re-implementation like html2canvas cannot draw, so the browser renders it
// itself through an SVG foreignObject. That route cannot fetch the images a
// mask refers to, so they are swapped for data URLs while the picture is taken.
const drawPlaque = async (element: HTMLElement, scale: number) => {
  const restore: (() => void)[] = [];

  const inline = async (node: HTMLElement, property: string) => {
    const url = urlOf(node.style.getPropertyValue(property));
    if (!url || url.startsWith("data:")) {
      return;
    }

    const previous = node.style.getPropertyValue(property);
    node.style.setProperty(property, `url(${await toDataUrl(url)})`);
    restore.push(() => node.style.setProperty(property, previous));
  };

  try {
    await inline(element, "--mark");
    await Promise.all(
      Array.from(
        element.querySelectorAll<HTMLElement>(".vehicle-plaque__emblem"),
      ).map((node) => inline(node, "--icon")),
    );

    const width = element.offsetWidth * scale;
    const height = element.offsetHeight * scale;

    // `width` and `height` size the picture, but dom-to-image also gives them
    // to the copy it lays out; pinned back to its own size here, which it
    // applies last, the copy is laid out as on screen and only then scaled.
    const svg = await domtoimage.toSvg(element, {
      cacheBust: true,
      width,
      height,
      style: {
        width: `${element.offsetWidth}px`,
        height: `${element.offsetHeight}px`,
        transform: `scale(${scale})`,
        transformOrigin: "top left",
      },
    });

    const image = await loadImage(withFontFaces(svg, await plaqueFontFaces()));

    const canvas = document.createElement("canvas");
    canvas.width = width;
    canvas.height = height;
    canvas.getContext("2d")?.drawImage(image, 0, 0);

    return canvas;
  } finally {
    restore.forEach((undo) => undo());
  }
};

const pngBlob = async (canvas: HTMLCanvasElement) => {
  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/png"),
  );
  if (!blob) {
    throw new Error("The plaque could not be drawn");
  }

  return blob;
};

export const plaqueFile = async (element: HTMLElement, filename: string) =>
  new File(
    [await pngBlob(await drawPlaque(element, SCALE))],
    `fleetyards-${filename}.png`,
    { type: "image/png" },
  );

// A Home Screen app on iOS ignores a download link, so there the picture goes
// to the share sheet, whose "Save Image" puts it in Photos. Only iOS sets
// `navigator.standalone`; installed apps elsewhere download as a tab does.
export const sharesPlaque = (file: File) =>
  (navigator as Navigator & { standalone?: boolean }).standalone === true &&
  !!navigator.canShare?.({ files: [file] });

export const savePlaque = async (file: File) => {
  if (sharesPlaque(file)) {
    await navigator.share({ files: [file] });
    return;
  }

  downloadJs(file, file.name, "image/png");
};

// Asked with a stand-in, since the plaque is only drawn once the button is
// pressed and the share sheet has to be offered before that.
export const canSharePlaques = () =>
  !!navigator.canShare?.({
    files: [new File([""], "plaque.png", { type: "image/png" })],
  });

export const sharePlaque = (file: File, title?: string) =>
  navigator.share({ files: [file], ...(title ? { title } : {}) });

// The plaque on a dark card of the size link previews use, for a shared link.
export const plaqueSocialImage = async (element: HTMLElement) => {
  if (!element.offsetWidth) {
    throw new Error("The plaque is not laid out");
  }

  const plaque = await drawPlaque(element, PREVIEW_WIDTH / element.offsetWidth);

  const canvas = document.createElement("canvas");
  canvas.width = PREVIEW_WIDTH;
  canvas.height = PREVIEW_HEIGHT;

  const context = canvas.getContext("2d");
  if (!context) {
    throw new Error("No canvas context");
  }

  context.fillStyle = PREVIEW_BACKGROUND;
  context.fillRect(0, 0, PREVIEW_WIDTH, PREVIEW_HEIGHT);

  const fit = Math.min(
    (PREVIEW_WIDTH - PREVIEW_PADDING * 2) / plaque.width,
    (PREVIEW_HEIGHT - PREVIEW_PADDING * 2) / plaque.height,
  );
  const width = plaque.width * fit;
  const height = plaque.height * fit;
  context.drawImage(
    plaque,
    (PREVIEW_WIDTH - width) / 2,
    (PREVIEW_HEIGHT - height) / 2,
    width,
    height,
  );

  return new File([await pngBlob(canvas)], "plaque.png", {
    type: "image/png",
  });
};
