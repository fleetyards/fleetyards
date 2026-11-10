import { ref } from "vue";

// Which ships are still waiting for their picture. Only the totals are reactive,
// and only the progress indicator reads them: a chart of thousands re-rendered on
// every picture that arrives would freeze the page.
export const createImageProgress = () => {
  const waiting = new Set<string>();
  const requested = ref(0);
  const outstanding = ref(0);

  const pending = (id: string) => {
    if (waiting.has(id)) {
      return;
    }

    // A round of loading starts with the first picture asked for and ends when
    // the last has arrived.
    if (!waiting.size) {
      requested.value = 0;
    }

    waiting.add(id);
    requested.value += 1;
    outstanding.value = waiting.size;
  };

  const settled = (id: string) => {
    if (waiting.delete(id)) {
      outstanding.value = waiting.size;
    }
  };

  return { requested, outstanding, pending, settled };
};

export type ImageProgress = ReturnType<typeof createImageProgress>;
