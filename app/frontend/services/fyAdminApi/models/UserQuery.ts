/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { UserSortEnum } from './UserSortEnum';
export type UserQuery = {
    searchCont?: string;
    usernameCont?: string;
    emailCont?: string;
    rsiHandleCont?: string;
    idIn?: Array<string>;
    usernameIn?: Array<string>;
    emailIn?: Array<string>;
    rsihandleIn?: Array<string>;
    sorts?: (Array<UserSortEnum> | UserSortEnum);
};

