import domtoimage from "dom-to-image";
import downloadJs from "downloadjs";

// Drawn at three times its size on screen, so a download stays sharp.
const SCALE = 3;

// The size platforms show a large link preview at.
const PREVIEW_WIDTH = 1200;
const PREVIEW_HEIGHT = 630;
const PREVIEW_PADDING = 36;
const PREVIEW_BACKGROUND = "#0d0f12";

const toDataUrl = async (url: string) => {
  const blob = await (await fetch(url)).blob();

  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
};

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
export const capturePlaque = async (element: HTMLElement, scale = SCALE) => {
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

    // `width` and `height` size the picture, but dom-to-image also gives them
    // to the copy it lays out; pinned back to its own size here, which it
    // applies last, the copy is laid out as on screen and only then scaled.
    return await domtoimage.toPng(element, {
      cacheBust: true,
      width: element.offsetWidth * scale,
      height: element.offsetHeight * scale,
      style: {
        width: `${element.offsetWidth}px`,
        height: `${element.offsetHeight}px`,
        transform: `scale(${scale})`,
        transformOrigin: "top left",
      },
    });
  } finally {
    restore.forEach((undo) => undo());
  }
};

export const downloadPlaque = async (
  element: HTMLElement,
  filename: string,
) => {
  downloadJs(
    await capturePlaque(element),
    `fleetyards-${filename}.png`,
    "image/png",
  );
};

// The plaque on a dark card of the size link previews use, for a shared link.
export const plaqueSocialImage = async (element: HTMLElement) => {
  const plaque = await loadImage(
    await capturePlaque(element, PREVIEW_WIDTH / element.offsetWidth),
  );

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

  const blob = await new Promise<Blob | null>((resolve) =>
    canvas.toBlob(resolve, "image/png"),
  );
  if (!blob) {
    throw new Error("The plaque could not be drawn");
  }

  return new File([blob], "plaque.png", { type: "image/png" });
};
