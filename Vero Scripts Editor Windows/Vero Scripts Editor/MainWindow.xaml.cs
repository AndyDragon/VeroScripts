﻿using System.ComponentModel;
using System.Diagnostics;
using System.IO;
using System.Reflection;
using System.Windows;
using System.Windows.Media;
using ICSharpCode.AvalonEdit;
using ICSharpCode.AvalonEdit.Highlighting;
using ICSharpCode.AvalonEdit.Highlighting.Xshd;
using MahApps.Metro.Controls;
using Notification.Wpf;

namespace VeroScriptsEditor
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : MetroWindow
    {
        private bool ignoreDirtyState = false;

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
                var assembly = Assembly.GetExecutingAssembly();
                using var stream = assembly.GetManifestResourceStream("VeroScriptsEditor.ScriptTemplate.xshd");
                if (stream != null)
                {
                    using var reader = new System.Xml.XmlTextReader(stream);
                    var syntax = HighlightingLoader.Load(reader, HighlightingManager.Instance);
                    HighlightingManager.Instance.RegisterHighlighting(
                        "ScriptTemplate",
                        [],
                        syntax);
                    textEditor.SyntaxHighlighting = syntax;
                    textEditor.TextArea.TextView.LinkTextForegroundBrush = Brushes.LightBlue;
                }
            }
        }

        private void OnActivatedChanged(object sender, EventArgs e)
        {
            if (this.DataContext is MainViewModel viewModel)
            {
                viewModel.WindowActive = IsActive;
            }
        }

        private async void OnClosing(object sender, CancelEventArgs e)
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

            if (this.DataContext is MainViewModel viewModel && viewModel.IsDirty && !ignoreDirtyState)
            {
                e.Cancel = true;
                var result = await MainViewModel.HandleDirtyAction(this, "Quit", "Are you sure you wish to quit?");
                switch (result)
                {
                    case MainViewModel.DirtyActionResult.Confirm:
                        ignoreDirtyState = true;
                        Close();
                        break;
                    case MainViewModel.DirtyActionResult.CopyReport:
                        {
                            var report = viewModel.GenerateReport();
                            if (!string.IsNullOrEmpty(report))
                            {
                                viewModel.CopyTextToClipboard(report, "Report generated", "The report has been copied to the clipboard");
                                Logger.LogInfo("Generated report and copied to clipboard");
                                await Task.Delay(1400);
                            }
                            ignoreDirtyState = true;
                            Close();
                        }
                        break;
                    case MainViewModel.DirtyActionResult.SaveReport:
                        {
                            var report = viewModel.GenerateReport();
                            if (string.IsNullOrEmpty(report))
                            {
                                ignoreDirtyState = true;
                                Close();
                            }
                            if (viewModel.SaveReport(report))
                            {
                                Logger.LogInfo("Generated report and saved to file");
                                await Task.Delay(1400);
                                ignoreDirtyState = true;
                                Close();
                            }
                        }
                        break;
                }
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
