import { IControlCentreDataService } from '../../../common/SharePointDataService';

export interface IPeopleDeliveryTimelineProps {
  title: string;
  pageId: string;
  isDarkTheme: boolean;
  dataService: IControlCentreDataService;
}
