type ProgressTrackerItem = {
  id: string
}

type ProgressTrackerItemSorting = {
  title: string
}

type ProgressTrackerItemQuery = {
  team: string[]
  // eslint-disable-next-line camelcase
  in_progress: boolean
  done: boolean
  planned: boolean
}

interface ProgressTrackerItemParams extends CollectionParams {
  search?: string
  order?: ProgressTrackerItemSorting
  query?: ProgressTrackerItemQuery
}
