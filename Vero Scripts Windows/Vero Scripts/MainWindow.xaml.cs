using System;
using System.Windows;
using System.Windows.Controls;
using FramePFX.Themes;
using Microsoft.Win32;
using Vero_Scripts.Properties;

namespace Vero_Scripts
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : Window
    {
        public MainWindow()
        {
            InitializeComponent();

            var theme = Settings.Default.Theme;
            switch (theme)
            {
                case "SoftDark": ThemesController.SetTheme(ThemeType.SoftDark); break;
                case "LightTheme": ThemesController.SetTheme(ThemeType.LightTheme); break;
                case "DeepDark": ThemesController.SetTheme(ThemeType.DeepDark); break;
                case "DarkGreyTheme": ThemesController.SetTheme(ThemeType.DarkGreyTheme); break;
                case "GreyTheme": ThemesController.SetTheme(ThemeType.GreyTheme); break;
                default:
                    {
                        if (IsLightTheme())
                        {
                            ThemesController.SetTheme(ThemeType.LightTheme);
                        }
                        break;
                    }
            }

            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.ThemeName = ThemesController.CurrentTheme.GetName();
            }
        }

        private static bool IsLightTheme()
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            var value = key?.GetValue("AppsUseLightTheme");
            return value is int i && i > 0;
        }

        private void OnThemeClick(object sender, RoutedEventArgs e)
        {
            switch (ThemesController.CurrentTheme.GetName())
            {
                case "SoftDark": ThemesController.SetTheme(ThemeType.LightTheme); break;
                case "LightTheme": ThemesController.SetTheme(ThemeType.DeepDark); break;
                case "DeepDark": ThemesController.SetTheme(ThemeType.DarkGreyTheme); break;
                case "DarkGreyTheme": ThemesController.SetTheme(ThemeType.GreyTheme); break;
                case "GreyTheme": ThemesController.SetTheme(ThemeType.SoftDark); break;
            }

            Settings.Default.Theme = ThemesController.CurrentTheme.GetName();
            Settings.Default.Save();

            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.ThemeName = ThemesController.CurrentTheme.GetName();
            }
        }

        private void OnClearUserClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.ClearUser();
            }
        }

        private void OnCopyFeatureScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.Feature, force: true);
            }
        }

        private void OnCopyFeatureScriptWithPlaceholdersClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.Feature, withPlaceholders: true);
            }
        }

        private void OnCopyCommentScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.Comment, force: true);
            }
        }

        private void OnCopyCommentScriptWithPlaceholdersClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.Comment, withPlaceholders: true);
            }
        }

        private void OnCopyOriginalPostScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.OriginalPost, force: true);
            }
        }

        private void OnCopyOriginalPostScriptWithPlaceholdersClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyScript(this, Script.OriginalPost, withPlaceholders: true);
            }
        }

        private void OnCopyNewMembershipScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                viewModel.CopyNewMembershipScript();
            }
        }
    }
}