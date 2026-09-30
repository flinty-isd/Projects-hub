using System;
using System.Collections.Generic;
using System.Web;

namespace ItGovernanceSite.App_Code
{
    public class GovernanceData
    {
        public List<PolicyItem> Policies { get; set; }
        public List<ControlItem> Controls { get; set; }
        public List<FindingItem> Findings { get; set; }
        public List<GovernanceRiskItem> Risks { get; set; }
        public List<ExceptionItem> Exceptions { get; set; }
        public bool IsLive { get; set; }
        public string LoadError { get; set; }
    }

    /// <summary>Loads live SharePoint data when configured, falling back to demo data
    /// on missing config or any Graph error so the site always renders.</summary>
    public static class DashboardDataProvider
    {
        private const string CacheKey = "ItGovernanceData";
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

        public static GovernanceData Load(bool forceRefresh = false)
        {
            var cached = HttpRuntime.Cache[CacheKey] as GovernanceData;
            if (!forceRefresh && cached != null)
            {
                return cached;
            }

            var data = LoadInternal();
            if (data.IsLive)
            {
                HttpRuntime.Cache.Insert(
                    CacheKey, data, null,
                    DateTime.Now.Add(CacheDuration),
                    System.Web.Caching.Cache.NoSlidingExpiration);
            }
            else
            {
                HttpRuntime.Cache.Remove(CacheKey);
            }
            return data;
        }

        private static GovernanceData LoadInternal()
        {
            var config = SharePointConfig.LoadFromAppSettings();
            if (config == null)
            {
                return DemoData(null);
            }

            try
            {
                var client = new SharePointClient(config);
                return new GovernanceData
                {
                    Policies = client.GetPoliciesAsync().GetAwaiter().GetResult(),
                    Controls = client.GetControlsAsync().GetAwaiter().GetResult(),
                    Findings = client.GetFindingsAsync().GetAwaiter().GetResult(),
                    Risks = client.GetRisksAsync().GetAwaiter().GetResult(),
                    Exceptions = client.GetExceptionsAsync().GetAwaiter().GetResult(),
                    IsLive = true,
                };
            }
            catch (Exception ex)
            {
                return DemoData(ex.Message);
            }
        }

        private static GovernanceData DemoData(string loadError)
        {
            return new GovernanceData
            {
                Policies = MockData.GetSamplePolicies(),
                Controls = MockData.GetSampleControls(),
                Findings = MockData.GetSampleFindings(),
                Risks = MockData.GetSampleRisks(),
                Exceptions = MockData.GetSampleExceptions(),
                IsLive = false,
                LoadError = loadError,
            };
        }
    }
}
