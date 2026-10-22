import { plaqueSocialImage } from "@/frontend/components/Vehicles/Plaque/download";
import { useDirectUpload } from "@/shared/composables/useDirectUpload";

// The plaque as a picture, for the preview of a shared link. Rendered in the
// browser because only the browser can draw it; a failure leaves the plaque
// saved and only its preview behind, which falls back to the hangar's own until
// the next save.
export const usePlaqueImageUpload = (
  attach: (signedId: string) => Promise<unknown>,
) => {
  const { uploadFile } = useDirectUpload();

  const capturing = ref(false);

  const upload = async (plaque?: HTMLElement | null) => {
    if (!plaque) {
      return;
    }

    capturing.value = true;

    try {
      const file = await plaqueSocialImage(plaque);
      const blob = await uploadFile(file, { progressHandler: () => undefined });

      await attach(blob.signed_id);
    } catch {
      // The plaque itself is saved.
    } finally {
      capturing.value = false;
    }
  };

  return { capturing, upload };
};
