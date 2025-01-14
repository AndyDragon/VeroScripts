using System.IO;
using System.Reflection;
using System.Windows;

using ControlzEx.Theming;
using ZeroLog;
using ZeroLog.Appenders;
using ZeroLog.Configuration;

namespace VeroScriptsEditor
{
    /// <summary>
    /// Interaction logic for App.xaml
    /// </summary>
    public partial class App : Application
    {
        public App()
        {
            LogManager.Initialize(new ZeroLogConfiguration
            {
                RootLogger =
                {
                    Appenders =
                    {
                        new ConsoleAppender(),
                        new DateAndSizeRollingFileAppender(
                            Path.Combine(
                                Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), 
                                "Vero Scripts Editor")) 
                        { 
                            Level = LogLevel.Info, 
                            MaxFileSizeInBytes = 1024 * 1024 
                        }
                    }
                }
            });
        }

        protected override void OnStartup(StartupEventArgs e)
        {
            Logger.LogInfo("==========================================================================");
            Logger.LogInfo("Started session running version " + (Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---"));
         
            static void HandleExceptionLogging(Exception ex)
            {
                try
                {
                    Logger.LogFatal(ex.ToString());
                    MessageBox.Show(ex.ToString(), "Fatal application exception, please report to AndyDragon", MessageBoxButton.OK);
                    // Danger! Trying to save a file in the middle of a crash, should work?
                    File.WriteAllText(Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "Vero Scripts Editor.crashlog"), ex.ToString());
                }
                catch
                {
                    // Application is already crashing, don't add to the problem...
                }
            }

            // Handle errors on main thread.
            AppDomain.CurrentDomain.UnhandledException += (sender, e) =>
            {
                if (e.ExceptionObject is Exception ex)
                {
                    HandleExceptionLogging(ex);
                }
            };

            // Handle errors on other threads using the task scheduler.
            TaskScheduler.UnobservedTaskException += (sender, e) =>
            {
                if (e.Exception is Exception ex)
                {
                    HandleExceptionLogging(ex);
                }
            };

            base.OnStartup(e);

            ThemeManager.Current.ThemeSyncMode = ThemeSyncMode.SyncAll;

            ThemeManager.Current.SyncTheme();

            var lastThemeName = UserSettings.Get<string>("theme");
            if (!string.IsNullOrEmpty(lastThemeName))
            {
                ThemeManager.Current.ChangeTheme(this, lastThemeName);
                Logger.LogInfo($"Set initial theme to {lastThemeName}");
            }
        }

        protected override void OnExit(ExitEventArgs e)
        {
            base.OnExit(e);

            Logger.LogInfo("Ended session");
            Logger.LogInfo("==========================================================================");
            LogManager.Shutdown();
        }
    }

    public class Logger
    {
        public static void LogInfo(string message)
        {
            Default.Info(message);
        }

        public static void LogWarning(string message)
        {
            Default.Warn(message);
        }

        public static void LogError(string message)
        {
            Default.Error(message);
        }

        public static void LogFatal(string message)
        {
            Default.Fatal(message);
        }

        private static readonly Log Default = LogManager.GetLogger("Vero Scripts Editor");
    }
}
