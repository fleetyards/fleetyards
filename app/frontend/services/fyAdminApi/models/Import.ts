/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ImportStatusEnum } from './ImportStatusEnum';
import type { ImportTypeEnum } from './ImportTypeEnum';
export type Import = {
    id: string;
    type: ImportTypeEnum;
    status: ImportStatusEnum;
    info?: string;
    version?: string;
    input?: string;
    output?: string;
    import?: string;
    importData?: string;
    startedAt?: string;
    finishedAt?: string;
    failedAt?: string;
    createdAt: string;
    updatedAt: string;
};

