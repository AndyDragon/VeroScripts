using MahApps.Metro.Controls;

namespace VeroScripts
{
    /// <summary>
    /// Interaction logic for MainWindow.xaml
    /// </summary>
    public partial class MainWindow : MetroWindow
    {
        public MainWindow()
        {
            InitializeComponent();
        }

        private void OnActivatedChanged(object sender, EventArgs e)
        {
            if (this.DataContext is ScriptsViewModel viewModel)
            {
                viewModel.WindowActive = IsActive;
            }
        }
    }
}