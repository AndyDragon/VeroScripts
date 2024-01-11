using System;
using System.Windows;
using FramePFX.Themes;
using Microsoft.Win32;

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
            if (IsLightTheme())
            {
                ThemesController.SetTheme(ThemeType.LightTheme);
            }
        }

        private static bool IsLightTheme()
        {
            using var key = Registry.CurrentUser.OpenSubKey(@"Software\Microsoft\Windows\CurrentVersion\Themes\Personalize");
            var value = key?.GetValue("AppsUseLightTheme");
            return value is int i && i > 0;
        }

        private void OnCopyFeatureScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.FeatureScript, new[] { viewModel.CommentScript, viewModel.OriginalPostScript });
            }
        }

        private void OnCopyFeatureScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.FeatureScript, new[] { viewModel.CommentScript, viewModel.OriginalPostScript}, true);
            }
        }

        private void OnCopyCommentScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.CommentScript, new[] { viewModel.FeatureScript, viewModel.OriginalPostScript });
            }
        }

        private void OnCopyCommentScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.CommentScript, new[] { viewModel.FeatureScript, viewModel.OriginalPostScript }, true);
            }
        }

        private void OnCopyOriginalPostScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.OriginalPostScript, new[] { viewModel.FeatureScript, viewModel.CommentScript });
            }
        }

        private void OnCopyOriginalPostScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                CopyScript(viewModel, viewModel.OriginalPostScript, new[] { viewModel.FeatureScript, viewModel.CommentScript }, true);
            }
        }

        private void CopyScript(ScriptsViewModel viewModel, string script, string[] otherScripts, bool force = false)
        {
            var allScripts = (new[] { script }).Concat(otherScripts).ToArray();
            if (viewModel.CheckForPlaceholders(allScripts, force))
            {
                var editor = new PlaceholderEditor(viewModel, script)
                {
                    Owner = this
                };
                if (!(editor.ShowDialog() ?? false))
                {
                    viewModel.Placeholders.Clear();
                }
            }
            else
            {
                var processedFeatureScript = viewModel.ProcessPlaceholders(script);
                Clipboard.SetText(processedFeatureScript);
            }
        }

        private void OnCopyNewMembershipScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                Clipboard.SetText(viewModel.NewMembershipScript);
            }
        }
    }
}