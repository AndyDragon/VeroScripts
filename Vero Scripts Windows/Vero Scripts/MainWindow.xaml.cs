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
                var processedFeatureScript = viewModel.ProcessPlaceholders(viewModel.FeatureScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    processedFeatureScript, viewModel.CommentScript, viewModel.OriginalPostScript }))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.FeatureScript)
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
                    Clipboard.SetText(processedFeatureScript);
                }
            }
        }

        private void OnCopyFeatureScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                var processedFeatureScript = viewModel.ProcessPlaceholders(viewModel.FeatureScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    processedFeatureScript, viewModel.CommentScript, viewModel.OriginalPostScript }, true))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.FeatureScript)
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
                    Clipboard.SetText(processedFeatureScript);
                }
            }
        }

        private void OnCopyCommentScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                var processedCommentScript = viewModel.ProcessPlaceholders(viewModel.CommentScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    viewModel.FeatureScript, processedCommentScript, viewModel.OriginalPostScript }))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.CommentScript)
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
                    Clipboard.SetText(processedCommentScript);
                }
            }
        }

        private void OnCopyCommentScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                var processedCommentScript = viewModel.ProcessPlaceholders(viewModel.CommentScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    viewModel.FeatureScript, processedCommentScript, viewModel.OriginalPostScript }, true))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.CommentScript)
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
                    Clipboard.SetText(processedCommentScript);
                }
            }
        }

        private void OnCopyOriginalPostScriptClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                var processedOriginalPostScript = viewModel.ProcessPlaceholders(viewModel.OriginalPostScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    viewModel.FeatureScript, viewModel.CommentScript, processedOriginalPostScript }))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.OriginalPostScript)
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
                    Clipboard.SetText(processedOriginalPostScript);
                }
            }
        }

        private void OnCopyOriginalPostScriptWithEditClick(object sender, RoutedEventArgs e)
        {
            if (DataContext is ScriptsViewModel viewModel)
            {
                var processedOriginalPostScript = viewModel.ProcessPlaceholders(viewModel.OriginalPostScript);
                if (viewModel.CheckForPlaceholders(new[] {
                    viewModel.FeatureScript, viewModel.CommentScript, processedOriginalPostScript }, true))
                {
                    var editor = new PlaceholderEditor(viewModel, viewModel.OriginalPostScript)
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
                    Clipboard.SetText(processedOriginalPostScript);
                }
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