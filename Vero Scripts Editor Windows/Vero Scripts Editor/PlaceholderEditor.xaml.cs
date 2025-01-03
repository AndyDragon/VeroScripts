using MahApps.Metro.Controls;
using System.Windows;

namespace VeroScriptsEditor
{
    /// <summary>
    /// Interaction logic for PlaceholderEditor.xaml
    /// </summary>
    public partial class PlaceholderEditor : MetroWindow
    {
        public PlaceholderEditor(MainViewModel viewModel)
        {
            InitializeComponent();
            this.DataContext = new PlaceholdersViewModel(viewModel);
        }

        private void OnCopyClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                viewModel.ViewModel.CopyScriptFromPlaceholders();
            }
            DialogResult = true;
            Close();
        }

        private void OnCopyUnchangedClick(object sender, RoutedEventArgs e)
        {
            if (this.DataContext is PlaceholdersViewModel viewModel)
            {
                viewModel.ViewModel.CopyScriptFromPlaceholders(withPlaceholders: true);
            }
            DialogResult = true;
            Close();
        }
    }
}
