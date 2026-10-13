// Some exports run past 100 MB, which no phone parses and decodes without
// being killed. Above this a phone or tablet asks first instead of loading
// straight away. Decimal, like the size it names.
export const LOW_POWER_HOLO_SIZE_LIMIT = 30_000_000;
