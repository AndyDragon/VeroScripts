using System;
using System.Windows;

namespace Vero_Scripts
{
    /// <summary>
    /// Interaction logic for PlaceholderEditor.xaml
    /// </summary>
    public partial class PlaceholderEditor : Window
    {
        private readonly string unprocessedScript;

        public PlaceholderEditor(ScriptsViewModel viewModel, string unprocessedScript)
        {
            InitializeComponent();
            this.DataContext = viewModel;
            this.unprocessedScript = unprocessedScript;
        }

        private void OnCopyClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is ScriptsViewModel viewModel)
            {
                Clipboard.SetText(viewModel.ProcessPlaceholders(unprocessedScript));
            }
            DialogResult = true;
            Close();
        }

        private void OnCopyUnchangedClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is ScriptsViewModel)
            {
                Clipboard.SetText(unprocessedScript);
            }
            DialogResult = true;
            Close();
        }
    }
}
