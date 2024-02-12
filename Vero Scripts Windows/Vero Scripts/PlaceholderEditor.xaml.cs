using System;
using System.Windows;

namespace Vero_Scripts
{
    /// <summary>
    /// Interaction logic for PlaceholderEditor.xaml
    /// </summary>
    public partial class PlaceholderEditor : Window
    {
        private readonly Script script;

        public PlaceholderEditor(ScriptsViewModel viewModel, Script script)
        {
            InitializeComponent();
            this.DataContext = new PlaceholdersViewModel(viewModel, script);
            this.script = script;
        }

        private void OnCopyClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                viewModel.ScriptsViewModel.TransferPlaceholders(script);
                Clipboard.SetText(viewModel.ScriptsViewModel.ProcessPlaceholders(script));
            }
            DialogResult = true;
            Close();
        }

        private void OnCopyUnchangedClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                Clipboard.SetText(viewModel.ScriptsViewModel.Scripts[script]);
            }
            DialogResult = true;
            Close();
        }
    }
}
