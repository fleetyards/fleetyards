// Systems CIG has shown but the game files do not have yet, drawn so the jump
// points that already lead to them have somewhere to go. Each one steps aside
// on its own once a listed system carries its name.
//
// The colours are read off CIG's system overviews, the star's from its
// spectral class where the lore gives one; nothing here comes from the game.
export interface PlaceholderBody {
  name: string;
  color: string;
  // A surface the globe knows: "cratered", "gas_giant", … Rocky when unset.
  bodyType?: string;
}

export interface PlaceholderSystem {
  id: string;
  name: string;
  star: PlaceholderBody;
  // In orbit order, as CIG's system overviews show them.
  planets: PlaceholderBody[];
  // Announced connections the game files have no jump point for yet, by the
  // name a jump point would give the system at the other end.
  jumpsTo: string[];
}

export const PLACEHOLDER_SYSTEMS: PlaceholderSystem[] = [
  {
    id: "placeholder-castra",
    name: "Castra System",
    star: { name: "Castra", color: "#ffb066" },
    planets: [
      { name: "Castra", color: "#a89a45" },
      { name: "Cascom", color: "#9a5e5a" },
    ],
    jumpsTo: ["Nyx"],
  },
  {
    id: "placeholder-terra",
    name: "Terra System",
    star: { name: "Terra", color: "#ffe08a" },
    planets: [
      { name: "Aero", color: "#a5583a" },
      { name: "Gen", color: "#4f88a8" },
      { name: "Terra", color: "#6f8a6a" },
      { name: "Pike", color: "#85878c", bodyType: "cratered" },
    ],
    jumpsTo: [],
  },
];

// The name a jump point gives its destination: "Terra" for the Terra System.
export const placeholderDestination = (placeholder: PlaceholderSystem) =>
  placeholder.star.name.toLowerCase();
