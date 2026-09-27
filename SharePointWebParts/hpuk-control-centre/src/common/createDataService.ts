import { Environment, EnvironmentType } from '@microsoft/sp-core-library';
import { WebPartContext } from '@microsoft/sp-webpart-base';
import { IControlCentreDataService, SharePointControlCentreDataService, MockControlCentreDataService } from './SharePointDataService';

/**
 * Standard SPFx pattern: use mock data automatically in the local workbench
 * (there's no real "current site" list data to read there), and real
 * SharePoint REST calls everywhere else (SharePoint page, Teams, Viva).
 */
export function createDataService(context: WebPartContext): IControlCentreDataService {
  if (Environment.type === EnvironmentType.Local) {
    return new MockControlCentreDataService();
  }
  return new SharePointControlCentreDataService(context);
}
