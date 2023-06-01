type RoadmapItem = {
  id: string;
  released: boolean;
  recentlyUpdated: boolean;
  active: boolean;
  committed: boolean;
  completed: number;
  tasks: number;
  model?: Model;
  name: string;
  description?: string;
  release: string;
  releaseDescription?: string;
  body?: string;
  lastVersionChangedAt: Date;
  lastVersionChangedAtLabel: string;
  lastVersion: RoadmapVersionItem;
  image: string;
  media: {
    storeImage?: FyMediaImage;
  };
};

type RoadmapVersionItem = {
  active: {
    old: boolean | null;
    new: boolean | null;
  }[];
  released: {
    old: boolean | null;
    new: boolean | null;
  }[];
  release: {
    old: string | null;
    new: string | null;
  }[];
  committed: {
    old: number | null;
    new: number | null;
  }[];
  tasks: {
    old: number | null;
    new: number | null;
  }[];
};

type RoadmapItemsByRelease = {
  [release: string]: RoadmapItem[];
};
