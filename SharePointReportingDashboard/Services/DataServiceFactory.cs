using System;
using System.Configuration;

namespace SharePointReportingDashboard.Services
{
    /// <summary>
    /// Single place that decides which IProjectControlDataService
    /// implementation backs the Control Centre. Today "UseMockData" is
    /// always true. To connect the real SharePoint tenant, add a
    /// CsomProjectControlDataService (or PnP-based) class reading the six
    /// authoritative Lists, then return it here when UseMockData is false.
    /// </summary>
    public static class DataServiceFactory
    {
        private static readonly IProjectControlDataService MockInstance = new MockProjectControlDataService();

        public static IProjectControlDataService GetService()
        {
            var useMockData = true;
            bool.TryParse(ConfigurationManager.AppSettings["UseMockData"], out useMockData);

            if (useMockData)
            {
                return MockInstance;
            }

            throw new NotImplementedException(
                "UseMockData is false, but no real SharePoint implementation of " +
                "IProjectControlDataService has been wired up yet. Implement one against " +
                "the Migration Register, Page Delivery Register, Actions, RAID, Decisions " +
                "and Project Updates Lists, then return it from DataServiceFactory.GetService().");
        }
    }
}
