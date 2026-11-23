import { useUpdateProfile } from "@/services/fyApi";
import { useDirectUpload } from "@/shared/composables/useDirectUpload";
import { useSessionStore } from "@/frontend/stores/session";

// Keeps the two pictures of the default outfit, with and without its helmet,
// on the user beside the uploaded avatar.
export const useCharacterAvatarUpload = () => {
  const { uploadFile } = useDirectUpload();
  const updateProfile = useUpdateProfile();
  const sessionStore = useSessionStore();

  const signedId = async (portrait: Blob | null, name: string) => {
    if (!portrait) return undefined;

    const file = new File([portrait], name, { type: "image/png" });
    const blob = await uploadFile(file, { progressHandler: () => undefined });

    return blob.signed_id;
  };

  const upload = async ([helmet, bare]: (Blob | null)[]) => {
    const [characterAvatarHelmet, characterAvatarBare] = await Promise.all([
      signedId(helmet ?? null, "character-helmet.png"),
      signedId(bare ?? null, "character-bare.png"),
    ]);
    if (!characterAvatarHelmet && !characterAvatarBare) return false;

    await updateProfile.mutateAsync({
      data: { characterAvatarHelmet, characterAvatarBare },
    });
    await sessionStore.refreshUser();

    return true;
  };

  return { upload };
};
