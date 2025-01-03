using System.ComponentModel;
using System.IO;
using System.Windows;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using MahApps.Metro.Controls;

namespace VeroScriptsEditor
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : MetroWindow
    {
        public MainWindow()
        {
            InitializeComponent();
            if (DataContext is MainViewModel vm && textEditor != null)
            {
                vm.MainWindow = this;
                vm.TemplateTextEditor = textEditor;
                textEditor.Document.TextChanged += (object? sender, EventArgs e) =>
                {
                    if (vm.SelectedTemplate != null)
                    {
                        vm.UpdateScript();
                    }
                };
                using var stream = File.OpenRead("ScriptTemplate.xshd");
                using var reader = new System.Xml.XmlTextReader(stream);
                var syntax = HighlightingLoader.Load(reader, HighlightingManager.Instance);
                HighlightingManager.Instance.RegisterHighlighting(
                    "ScriptTemplate",
                    [],
                    syntax);
                textEditor.SyntaxHighlighting = syntax;
            }
        }

        private void OnActivatedChanged(object sender, EventArgs e)
        {
            if (this.DataContext is MainViewModel viewModel)
            {
                viewModel.WindowActive = IsActive;
            }
        }

        private void OnClosing(object sender, CancelEventArgs e)
        {
            if (WindowState == WindowState.Maximized)
            {
                // Use the RestoreBounds as the current values will be 0, 0 and the size of the screen
                Properties.Settings.Default.Top = RestoreBounds.Top;
                Properties.Settings.Default.Left = RestoreBounds.Left;
                Properties.Settings.Default.Height = RestoreBounds.Height;
                Properties.Settings.Default.Width = RestoreBounds.Width;
                Properties.Settings.Default.Maximized = true;
            }
            else
            {
                Properties.Settings.Default.Top = Top;
                Properties.Settings.Default.Left = Left;
                Properties.Settings.Default.Height = Height;
                Properties.Settings.Default.Width = Width;
                Properties.Settings.Default.Maximized = false;
            }
            Properties.Settings.Default.Save();

            if (this.DataContext is MainViewModel viewModel && viewModel.IsDirty)
            {
                e.Cancel = true;
                viewModel.HandleDirtyAction(exit => e.Cancel = !exit);
            }
        }

        private void OnDataContextChanged(object sender, DependencyPropertyChangedEventArgs e)
        {
            if (DataContext is MainViewModel vm && textEditor != null)
            {
                vm.MainWindow = this;
            }
        }

        private void OnSourceInitialized(object sender, EventArgs e)
        {
            this.Top = Properties.Settings.Default.Top;
            this.Left = Properties.Settings.Default.Left;
            this.Height = Properties.Settings.Default.Height;
            this.Width = Properties.Settings.Default.Width;
            // Very quick and dirty - but it does the job
            if (Properties.Settings.Default.Maximized)
            {
                WindowState = WindowState.Maximized;
            }
        }
    }
}
