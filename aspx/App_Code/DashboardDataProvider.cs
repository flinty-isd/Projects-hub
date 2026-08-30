using System;
using System.Collections.Generic;
using System.Web;

namespace SharePointPmDashboard.App_Code
{
    public class DashboardData
    {
        public List<TaskItem> Tasks { get; set; }
        public List<RiskItem> Risks { get; set; }
        public bool IsLive { get; set; }
        public string LoadError { get; set; }
    }

    /// <summary>Loads live SharePoint data when configured, falling back to demo data
    /// on missing config or any Graph error, mirroring load_data() in streamlit_app.py.</summary>
    public static class DashboardDataProvider
    {
        private const string CacheKey = "SharePointDashboardData";
        private static readonly TimeSpan CacheDuration = TimeSpan.FromMinutes(5);

        public static DashboardData Load(bool forceRefresh = false)
        {
            var cachedObj = HttpRuntime.Cache[CacheKey];
            if (!forceRefresh && cachedObj is DashboardData)
            {
                return (DashboardData)cachedObj;
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

        private static DashboardData LoadInternal()
        {
            var config = SharePointConfig.LoadFromAppSettings();
            if (config == null)
            {
                return new DashboardData
                {
                    Tasks = MockData.GetSampleTasks(),
                    Risks = MockData.GetSampleRisks(),
                    IsLive = false,
                };
            }

            try
            {
                var client = new SharePointClient(config);
                var tasks = client.GetTasksAsync().GetAwaiter().GetResult();
                var risks = client.GetRisksAsync().GetAwaiter().GetResult();
                return new DashboardData { Tasks = tasks, Risks = risks, IsLive = true };
            }
            catch (Exception ex)
            {
                return new DashboardData
                {
                    Tasks = MockData.GetSampleTasks(),
                    Risks = MockData.GetSampleRisks(),
                    IsLive = false,
                    LoadError = ex.Message,
                };
            }
        }
    }
}
