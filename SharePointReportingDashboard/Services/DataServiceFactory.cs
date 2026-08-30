using System;
using System.Configuration;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Single place that decides which ISharePointDataService implementation
    /// backs the dashboard. Today "UseMockData" is always true. To connect a
    /// real tenant, add a CsomSharePointDataService (or PnP-based) class,
    /// then return it here when UseMockData is false.
    /// </summary>
    public static class DataServiceFactory
    {
        private static readonly ISharePointDataService MockInstance = new MockSharePointDataService();

        public static ISharePointDataService GetService()
        {
            var useMockData = true;
            bool.TryParse(ConfigurationManager.AppSettings["UseMockData"], out useMockData);

            if (useMockData)
            {
                return MockInstance;
            }

            throw new NotImplementedException(
                "UseMockData is false, but no real SharePoint implementation of " +
                "ISharePointDataService has been wired up yet. Implement one against " +
                "CSOM/PnP and return it from DataServiceFactory.GetService().");
        }
    }
}
