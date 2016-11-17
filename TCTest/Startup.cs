using Microsoft.Owin;
using Owin;

[assembly: OwinStartupAttribute(typeof(TCTest.Startup))]
namespace TCTest
{
    public partial class Startup
    {
        public void Configuration(IAppBuilder app)
        {
            ConfigureAuth(app);
        }
    }
}
