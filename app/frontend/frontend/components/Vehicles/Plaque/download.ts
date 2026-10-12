import domtoimage from "dom-to-image";
import downloadJs from "downloadjs";

const toDataUrl = async (url: string) => {
  const blob = await (await fetch(url)).blob();

  return new Promise<string>((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => resolve(reader.result as string);
    reader.onerror = reject;
    reader.readAsDataURL(blob);
  });
};

const SCALE = 3;

const urlOf = (value: string) => value.match(/url\(["']?([^"')]+)["']?\)/)?.[1];

// The plaque is drawn with clip-paths, masks and conic gradients that a canvas
// re-implementation like html2canvas cannot draw, so the browser renders it
// itself through an SVG foreignObject. That route cannot fetch the images a
// mask refers to, so they are swapped for data URLs while the picture is taken.
export const downloadPlaque = async (
  element: HTMLElement,
  filename: string,
) => {
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

    // Drawn at three times its size on screen, so the picture stays sharp.
    const png = await domtoimage.toPng(element, {
      cacheBust: true,
      width: element.offsetWidth * SCALE,
      height: element.offsetHeight * SCALE,
      style: {
        transform: `scale(${SCALE})`,
        transformOrigin: "top left",
      },
    });
    downloadJs(png, `fleetyards-${filename}.png`, "image/png");
  } finally {
    restore.forEach((undo) => undo());
  }
};
