/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { ModelSortEnum } from './ModelSortEnum';
export type ModelQuery = {
    nameCont?: string;
    idEq?: string;
    nameIn?: Array<string>;
    idIn?: Array<string>;
    idNotIn?: Array<string>;
    manufacturerIn?: Array<string>;
    productionStatusIn?: Array<string>;
    searchCont?: string;
    scIdentifierBlank?: boolean;
    fleetchartImageBlank?: boolean;
    holoBlank?: boolean;
    topViewColoredBlank?: boolean;
    frontViewBlank?: boolean;
    sorts?: (Array<ModelSortEnum> | ModelSortEnum);
};

