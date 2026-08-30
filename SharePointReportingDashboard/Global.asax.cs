using System;

namespace SharePointReportingDashboard
{
    public class Global : System.Web.HttpApplication
    {
        protected void Application_Start(object sender, EventArgs e)
        {
        }

        protected void Application_Error(object sender, EventArgs e)
        {
            Server.GetLastError();
        }
    }
}
