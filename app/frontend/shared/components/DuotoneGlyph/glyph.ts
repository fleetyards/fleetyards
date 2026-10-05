// A glyph on Font Awesome's grid, in its duotone shape: a faded secondary
// layer under a full primary one. `{id}` is replaced per rendered icon, so two
// icons on a page never share a mask.
export type Glyph = {
  // Font Awesome's wide icons are drawn on a 640 grid and render 1.25em wide.
  width?: 512 | 640;
  defs?: string;
  secondary: string;
  primary: string;
};

export const SECONDARY_STROKE =
  'stroke="var(--fa-secondary-color, currentColor)"';
export const PRIMARY_STROKE = 'stroke="var(--fa-primary-color, currentColor)"';

export const mask = (id: string, content: string) =>
  `<mask id="{id}-${id}" maskUnits="userSpaceOnUse" x="-64" y="-64" width="640" height="640"><rect x="-64" y="-64" width="640" height="640" fill="#fff"/>${content}</mask>`;

export const isGlyph = (icon: unknown): icon is Glyph =>
  typeof icon === "object" && icon !== null && "primary" in icon;

// What an icon prop or icon map holds: a Font Awesome class, or a glyph drawn
// here where Font Awesome has nothing fitting.
export type Icon = string | Glyph;

let glyphElements = 0;

// The same markup `DuotoneGlyph` renders, as a DOM element, for code that
// builds its nodes by hand rather than through a template.
export const glyphElement = (glyph: Glyph): SVGSVGElement => {
  glyphElements += 1;
  const id = `glyph-el-${glyphElements}`;
  const width = glyph.width ?? 512;
  const scoped = (markup?: string) => markup?.replaceAll("{id}", id) ?? "";
  const svg = document.createElementNS("http://www.w3.org/2000/svg", "svg");

  svg.setAttribute("class", "duotone-glyph");
  svg.setAttribute("viewBox", `0 0 ${width} 512`);
  svg.setAttribute("aria-hidden", "true");
  svg.setAttribute("focusable", "false");
  svg.setAttribute(
    "style",
    `display: inline-block; width: ${width / 512}em; height: 1em; vertical-align: -0.125em; overflow: visible`,
  );
  svg.innerHTML =
    `<defs>${scoped(glyph.defs)}</defs>` +
    `<g style="fill: var(--fa-secondary-color, currentColor); opacity: var(--fa-secondary-opacity, 0.4)">${scoped(glyph.secondary)}</g>` +
    `<g style="fill: var(--fa-primary-color, currentColor)">${scoped(glyph.primary)}</g>`;

  return svg;
};
