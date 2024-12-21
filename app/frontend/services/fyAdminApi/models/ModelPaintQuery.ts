/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ModelPaintSortEnum } from './ModelPaintSortEnum';
export type ModelPaintQuery = {
    nameEq?: string;
    nameCont?: string;
    idEq?: string;
    nameIn?: Array<string>;
    idIn?: Array<string>;
    idNotIn?: Array<string>;
    modelSlugIn?: Array<string>;
    modelSlugEq?: string;
    sorts?: (Array<ModelPaintSortEnum> | ModelPaintSortEnum);
};

