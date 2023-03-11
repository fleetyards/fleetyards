import { get, post, put, upload, destroy } from "@/frontend/api/client";
import BaseCollection from "./Base";

export class UserCollection extends BaseCollection<TUser, undefined> {
  async signup(form: TSignupForm): Promise<TRecordResponse<TUser>> {
    const response = await post<TUser>("users/signup", form);

    if (!response.error) {
      this.record = response.data;
    }

    return this.recordResponse(response.data, response.error, true);
  }

  async current(): Promise<TRecordResponse<TUser>> {
    const response = await get<TUser>("users/current");

    if (!response.error) {
      this.record = response.data;
    }

    return this.recordResponse(response.data, response.error, true);
  }

  async updateProfile(form: TUserForm): Promise<TRecordResponse<TUser>> {
    const response = await put<TUser>("users/current", form);

    return this.recordResponse(response.data, response.error);
  }

  async updateAccount(form: TUserAccountForm): Promise<TRecordResponse<TUser>> {
    const response = await put<TUser>("users/current-account", form);

    return this.recordResponse(response.data, response.error);
  }

  async uploadAvatar(uploadData: FormData): Promise<TRecordResponse<TUser>> {
    const response = await upload<TUser>("users/current", uploadData);

    return this.recordResponse(response.data, response.error);
  }

  async destroy(): Promise<TRecordResponse<TUser>> {
    const response = await destroy<TUser>("users/current");

    return this.recordResponse(response.data, response.error);
  }
}

export default new UserCollection();
