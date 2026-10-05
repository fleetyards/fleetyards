// A glyph on Font Awesome's 512 grid, in its duotone shape: a faded secondary
// layer under a full primary one. `{id}` is replaced per rendered icon, so two
// icons on a page never share a mask.
export type Glyph = {
  defs?: string;
  secondary: string;
  primary: string;
};

export const SECONDARY_STROKE =
  'stroke="var(--fa-secondary-color, currentColor)"';
export const PRIMARY_STROKE = 'stroke="var(--fa-primary-color, currentColor)"';

export const mask = (id: string, content: string) =>
  `<mask id="{id}-${id}" maskUnits="userSpaceOnUse" x="-64" y="-64" width="640" height="640"><rect x="-64" y="-64" width="640" height="640" fill="#fff"/>${content}</mask>`;

