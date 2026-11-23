using System.Collections.Generic;
using System.Linq;
using System.Web.SessionState;

namespace SharePointPmDashboard.App_Code
{
    /// <summary>Persists the Overview tab's status/owner filter selections in Session
    /// so the Timeline and KPIs tabs can apply the same filters (each .aspx page is a
    /// separate request, unlike the single-process Streamlit app's shared sidebar state).</summary>
    public static class FilterState
    {
        private const string StatusKey = "Filter.Statuses";
        private const string OwnerKey = "Filter.Owners";

        public static void Save(HttpSessionState session, List<string> statuses, List<string> owners)
        {
            session[StatusKey] = statuses;
            session[OwnerKey] = owners;
        }

        public static List<TaskItem> Apply(HttpSessionState session, List<TaskItem> tasks)
        {
            var statuses = session[StatusKey] as List<string>;
            var owners = session[OwnerKey] as List<string>;

            return tasks
                .Where(t => statuses == null || statuses.Count == 0 || statuses.Contains(t.Status))
                .Where(t => owners == null || owners.Count == 0 || owners.Contains(t.AssignedTo))
                .ToList();
        }
    }
}
