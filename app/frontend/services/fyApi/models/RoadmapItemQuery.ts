/* generated using openapi-typescript-codegen -- do not edit */
/* istanbul ignore file */
/* tslint:disable */
/* eslint-disable */
import type { RoadmapItemSortEnum } from './RoadmapItemSortEnum';
export type RoadmapItemQuery = {
    nameCont?: string;
    releasedEq?: boolean;
    updatedAtGteq?: string;
    updatedAtLteq?: string;
    lastUpdatedAtLteq?: string;
    lastUpdatedAtGteq?: string;
    activeEq?: boolean;
    lastUpdatedAtLt?: string;
    rsiReleaseIdGteq?: string;
    rsiCategoryIdIn?: Array<string>;
    activeIn?: Array<boolean>;
    sorts?: (Array<RoadmapItemSortEnum> | RoadmapItemSortEnum);
};

