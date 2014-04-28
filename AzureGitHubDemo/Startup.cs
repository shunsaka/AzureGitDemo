using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(AzureGitHubDemo.Startup))]
namespace AzureGitHubDemo
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
