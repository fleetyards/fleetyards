/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
export type AdminUser = {
    id?: string;
    username: string;
    email: string;
    twoFactorRequired: boolean;
    twoFactorQrCodeUrl?: string;
    twoFactorProvisioningUrl?: string;
    resourceAccess: Array<string>;
    superAdmin: boolean;
    createdAt: string;
    updatedAt: string;
};

