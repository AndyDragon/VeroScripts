using System.Collections.ObjectModel;
using System.ComponentModel;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

using ControlzEx.Theming;
using ICSharpCode.AvalonEdit;
using MahApps.Metro.Controls.Dialogs;
using Microsoft.Win32;
using Newtonsoft.Json;
using Notification.Wpf;

namespace VeroScriptsEditor
{
    public partial class MainViewModel : NotifyPropertyChanged
    {
        private readonly HttpClient httpClient = new();
        private readonly NotificationManager notificationManager = new();

        public MainViewModel()
        {
            _ = LoadPages();
            TemplatesCatalog = new TemplatesCatalog();

            ReloadPagesCatalogCommand = new CommandWithParameter(ReloadPages);
            CopyReportCommand = new Command(() =>
            {
                var report = GenerateReport();
                if (!string.IsNullOrEmpty(report))
                {
                    CopyTextToClipboard(report, "Report generated", "The report has been copied to the clipboard");
                    Logger.LogInfo("Generated report and copied to clipboard");
                }
            }, () => IsDirty);
            SaveReportCommand = new Command(() => 
            { 
                var report = GenerateReport();
                if (!string.IsNullOrEmpty(report) && SaveReport(report))
                {
                    Logger.LogInfo("Generated report and saved to file");
                }
            }, () => IsDirty);
            AddNewTemplateCommand = new Command(AddNewTemplate, CanAddNewTemplate);
            CopyTemplateCommand = new Command(CopyTemplate, CanCopyTemplate);
            PasteTemplateCommand = new Command(PasteTemplate);
            RevertTemplateCommand = new Command(RevertTemplate, CanRevertTemplate);
            RemoveTemplateCommand = new Command(RemoveTemplate, CanRemoveTemplate);
            InsertStaticPlaceholderCommand = new CommandWithParameter(InsertStaticPlaceholder);
            InsertManualPlaceholderCommand = new CommandWithParameter(InsertManualPlaceholder, CanInsertManualPlaceholder);
            CopyScriptCommand = new Command(CopyScript);
            SetThemeCommand = new CommandWithParameter(SetTheme);
			LaunchAboutCommand = new Command(LaunchAbout);
        }

        public TextEditor? TemplateTextEditor { get; internal set; }
        public MainWindow? MainWindow { get; internal set; }

        #region Editor manipulation

        private void PasteTemplateToEditor(string template)
        {
            if (TemplateTextEditor != null)
            {
                TemplateTextEditor.Text = template ?? string.Empty;
                TemplateTextEditor.Document.UndoStack.ClearAll();
                TemplateTextEditor.Focus();
            }
        }

        private void PasteTextToSelection(string text)
        {
            if (TemplateTextEditor != null)
            {
                TemplateTextEditor.BeginChange();
                TemplateTextEditor.SelectedText = text;
                TemplateTextEditor.Select(TemplateTextEditor.SelectionStart + TemplateTextEditor.SelectionLength, 0);
                TemplateTextEditor.EndChange();
                TemplateTextEditor.Focus();
            }
        }

        #endregion

        #region User settings

        public static string GetDataLocationPath()
        {
            var user = WindowsIdentity.GetCurrent();
            var dataLocationPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AndyDragonSoftware",
                "VeroScriptsEditor",
                user.Name);
            if (!Directory.Exists(dataLocationPath))
            {
                Directory.CreateDirectory(dataLocationPath);
            }
            return dataLocationPath;
        }

        public static string GetUserSettingsPath()
        {
            var dataLocationPath = GetDataLocationPath();
            return Path.Combine(dataLocationPath, "settings.json");
        }

        #endregion

        #region Server access

        private async Task LoadPages(bool manual = false)
        {
            try
            {
                Logger.LogInfo("Loading pages catalog" + (manual ? " (reload)" : ""));

                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var pagesUri = new Uri("https://vero.andydragon.com/static/data/pages.json");
                var content = await httpClient.GetStringAsync(pagesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    var pagesCatalog = JsonConvert.DeserializeObject<PagesCatalog>(content) ?? new PagesCatalog();

                    Logger.LogInfo($"Loaded pages catalog with {pagesCatalog.Hubs.Count} hubs and {pagesCatalog.Hubs.Sum(hub => hub.Value.Count)} pages");

                    // Have the pages, load the templates.
                    _ = LoadTemplates(pagesCatalog);
                }
                else
                {
                    throw new Exception("No content received");
                }
            }
            catch (Exception ex)
            {
                Logger.LogError($"Failed to load the page catalog: {ex.Message}");
                Logger.LogError(ex.ToString());
                ShowErrorToast(
                    "Failed to load the page catalog",
                    "The application requires the catalog to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadPages(); });
            }
        }

        private async Task LoadTemplates(PagesCatalog pagesCatalog)
        {
            try
            {
                Logger.LogInfo("Loading templates catalog");

                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var templatesUri = new Uri("https://vero.andydragon.com/static/data/templates.json");
                var content = await httpClient.GetStringAsync(templatesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    var templatesCatalog = JsonConvert.DeserializeObject<TemplatesCatalog>(content) ?? new TemplatesCatalog();

                    // Have the pages and the template pages, initialize the data model.
                    Catalog = new ObservableCatalog(pagesCatalog, templatesCatalog);
                    var lastPage = UserSettings.Get("Page", "");
                    SelectedPage = Catalog.Pages.FirstOrDefault(page => page.Id == lastPage) ?? Catalog.Pages.FirstOrDefault();
                    OnPropertyChanged(nameof(Catalog));
                    UpdateScript();

                    Logger.LogInfo($"Loaded templates catalog with {templatesCatalog.Pages.Length} template pages");
                }
                else
                {
                    throw new Exception("No content received");
                }
            }
            catch (Exception ex)
            {
                Logger.LogError($"Failed to load the page catalog: {ex.Message}");
                Logger.LogError(ex.ToString());
                ShowErrorToast(
                    "Failed to load the page templates",
                    "The application requires the templtes to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadTemplates(pagesCatalog); });
            }
        }

        #endregion

        #region Theme

        public TemplatesCatalog TemplatesCatalog { get; private set; }

        private Theme? theme = ThemeManager.Current.DetectTheme() ?? ThemeManager.Current.Themes.First();
        public Theme? Theme
        {
            get => theme;
            set
            {
                if (Set(ref theme, value))
                {
                    if (Theme != null)
                    {
                        Logger.LogInfo($"Set theme to {Theme.Name}");
                        ThemeManager.Current.ChangeTheme(Application.Current, Theme);
                        UserSettings.Store("theme", Theme.Name);
                        OnPropertyChanged(nameof(StatusBarBrush));
                        OnPropertyChanged(nameof(Themes));
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

        #endregion

        #region Miscellaneous

        public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";

        private bool windowActive = false;
        public bool WindowActive
        {
            get => windowActive;
            set
            {
                if (Set(ref windowActive, value))
                {
                    OnPropertyChanged(nameof(StatusBarBrush));
                }
            }
        }

        public Brush? StatusBarBrush => WindowActive
            ? Theme?.Resources["MahApps.Brushes.Accent2"] as Brush
            : Theme?.Resources["MahApps.Brushes.WindowTitle.NonActive"] as Brush;

        #endregion

        #region Dirty state

        public bool IsDirty
        {
            get => Catalog?.IsDirty ?? false;
        }

        public string Title => $"Vero Scripts Editor{(IsDirty ? " - some templates edited" : string.Empty)}";

        public enum DirtyActionResult
        {
            Confirm,
            Cancel,
            CopyReport,
            SaveReport,
        }

        public static async Task<DirtyActionResult> HandleDirtyAction(MainWindow window, string actionButon, string action)
        {
            var settings = new MetroDialogSettings()
            {
                AffirmativeButtonText = "Save report",
                NegativeButtonText = "Copy report",
                FirstAuxiliaryButtonText = "Cancel",
                SecondAuxiliaryButtonText = actionButon,
                DefaultButtonFocus = MessageDialogResult.Affirmative,
            };

            return await window.ShowMessageAsync(
                "Confirm",
                $"One or more templates have been added, removed or modified.\n\n{action}",
                MessageDialogStyle.AffirmativeAndNegativeAndDoubleAuxiliary,
                settings) switch
            {
                MessageDialogResult.Affirmative => DirtyActionResult.SaveReport,
                MessageDialogResult.Negative => DirtyActionResult.CopyReport,
                MessageDialogResult.SecondAuxiliary => DirtyActionResult.Confirm,
                _ => DirtyActionResult.Cancel,
            };
        }

        #endregion

        #region Script

        private string script = "";
        public string Script
        {
            get => script;
            set => Set(ref script, value, [nameof(ScriptPlaceholderVisibility), nameof(ScriptLength)]);
        }

        public int ScriptLength => Script.Length;

        public Visibility ScriptPlaceholderVisibility => ScriptHasPlaceholder() ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Catalog

        private ObservableCatalog? catalog;
        public ObservableCatalog? Catalog
        {
            get => catalog;
            set => Set(ref catalog, value);
        }

        #endregion

        #region Pages

        private ObservablePage? selectedPage = null;
        public ObservablePage? SelectedPage
        {
            get => selectedPage;
            set
            {
                if (Set(ref selectedPage, value, [nameof(Templates), nameof(IsDirty), nameof(Title), nameof(NewTemplates)]))
                {
                    SelectedNewTemplate = NewTemplates.FirstOrDefault();
                    var page = SelectedPage?.Id ?? string.Empty;
                    UserSettings.Store("Page", page);
                    if (!StaffLevels.Contains(StaffLevel))
                    {
                        StaffLevel = StaffLevels[0];
                    }
                    UserName = "reallylongartistalias";
                    YourName = "reallylongmoderatoralias";
                    YourFirstName = "MyReallyLongFirstName";
                    StaffLevel = "Co-Admin";
                    if (SelectedPage?.HubName == "snap")
                    {
                        Membership = "Hall of Fame Member";
                    }
                    else if (SelectedPage?.HubName == "click")
                    {
                        Membership = "Platinum Member";
                    }
                    else
                    {
                        Membership = "Artist";
                    }
                    UpdateScript();
                    CopyReportCommand.OnCanExecuteChanged();
                    SaveReportCommand.OnCanExecuteChanged();
                }
            }
        }

        #endregion

        #region Templates

        public ObservableCollection<ObservableTemplate> Templates
        {
            get
            {
                if (Catalog != null && SelectedPage != null)
                {
                    return Catalog.TemplatePages.FirstOrDefault(page => page.Name == SelectedPage.Id)?.Templates ?? [];
                }
                return [];
            }
        }

        private ObservableTemplate? selectedTemplate = null;
        public ObservableTemplate? SelectedTemplate
        {
            get => selectedTemplate;
            set
            {
                if (selectedTemplate != null)
                {
                    selectedTemplate.PropertyChanged -= SelectedTemplatePropertyChanged;
                }
                if (Set(ref selectedTemplate, value))
                {
                    PasteTemplateToEditor(SelectedTemplate?.Template ?? "");
                    if (selectedTemplate != null)
                    {
                        selectedTemplate.PropertyChanged += SelectedTemplatePropertyChanged;
                    }
                }
                OnPropertyChanged(nameof(IsDirty));
                CopyReportCommand.OnCanExecuteChanged();
                SaveReportCommand.OnCanExecuteChanged();
                OnPropertyChanged(nameof(Title));
                CopyTemplateCommand.OnCanExecuteChanged();
                RevertTemplateCommand.OnCanExecuteChanged();
                RemoveTemplateCommand.OnCanExecuteChanged();
                CopyScriptCommand.OnCanExecuteChanged();
            }
        }

        private void SelectedTemplatePropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            OnPropertyChanged(nameof(IsDirty));
            CopyReportCommand.OnCanExecuteChanged();
            SaveReportCommand.OnCanExecuteChanged();
            OnPropertyChanged(nameof(Title));
            CopyTemplateCommand.OnCanExecuteChanged();
            RevertTemplateCommand.OnCanExecuteChanged();
            RemoveTemplateCommand.OnCanExecuteChanged();
            CopyScriptCommand.OnCanExecuteChanged();
        }

        private readonly string[] clickTemplates =
            [
                "feature",
                "comment",
                "first comment",
                "community comment",
                "first community comment",
                "hub comment",
                "first hub comment",
                "original post"
            ];
        private readonly string[] snapTemplates = 
            [
                "feature",
                "comment",
                "first comment",
                "raw comment",
                "first raw comment",
                "community comment",
                "first community comment",
                "raw community comment",
                "first raw community comment",
                "original post"
            ];
        private readonly string[] otherTemplates =
            [
                "feature",
                "comment",
                "first comment",
                "original post"
            ];

        public string[] NewTemplates
        {
            get
            {
                if (Catalog != null && SelectedPage != null)
                {
                    var templatePage = Catalog.TemplatePages.FirstOrDefault(page => page.Name == SelectedPage.Id);
                    if (templatePage != null)
                    {
                        return SelectedPage.HubName switch
                        {
                            "click" => [.. clickTemplates.Where(clickTemplate => !templatePage.Templates.Any(template => template.Name == clickTemplate))],
                            "snap" => [.. snapTemplates.Where(snapTemplate => !templatePage.Templates.Any(template => template.Name == snapTemplate))],
                            _ => [.. otherTemplates.Where(otherTemplate => !templatePage.Templates.Any(template => template.Name == otherTemplate))],
                        };
                    }
                }
                return [];
            }
        }

        private string? selectedNewTemplate;
        public string? SelectedNewTemplate
        {
            get => selectedNewTemplate;
            set => SetWithCommands(ref selectedNewTemplate, value, [AddNewTemplateCommand]);
        }

        #endregion

        #region User name

        private string userName = "alphabeta";

        public string UserName
        {
            get => userName;
            set
            {
                if (Set(ref userName, value))
                {
                    UpdateScript();
                }
            }
        }

        #endregion

        #region Membership level

        private static string[] SnapMemberships => [
            "Artist",
            "Member",
            "VIP Member",
            "VIP Gold Member",
            "Platinum Member",
            "Elite Member",
            "Hall of Fame Member",
            "Diamond Member",
        ];

        private static string[] ClickMemberships => [
            "Artist",
            "Member",
            "Bronze Member",
            "Silver Member",
            "Gold Member",
            "Platinum Member",
        ];

        private static string[] OtherMemberships => [
            "Artist",
        ];

        public string[] HubMemberships =>
            SelectedPage?.HubName == "click" ? ClickMemberships :
            SelectedPage?.HubName == "snap" ? SnapMemberships :
            OtherMemberships;

        private string membership = "Artist";

        public string Membership
        {
            get => membership;
            set
            {
                if (Set(ref membership, value))
                {
                    UpdateScript();
                }
            }
        }

        #endregion

        #region Your name

        private string yourName = "omegazeta";

        public string YourName
        {
            get => yourName;
            set
            {
                if (Set(ref yourName, value))
                {
                    UpdateScript();
                }
            }
        }

        #endregion

        #region Your first name

        private string yourFirstName = "Omega";

        public string YourFirstName
        {
            get => yourFirstName;
            set
            {
                if (Set(ref yourFirstName, value))
                {
                    UpdateScript();
                }
            }
        }

        #endregion

        #region Staff level

        public static string[] SnapStaffLevels => [
            "Mod",
            "Co-Admin",
            "Admin",
            "Guest moderator"
        ];

        public static string[] ClickStaffLevels => [
            "Mod",
            "Co-Admin",
            "Admin",
        ];

        public static string[] OtherStaffLevels => [
            "Mod",
            "Co-Admin",
            "Admin",
        ];

        public string[] StaffLevels =>
            SelectedPage?.HubName == "click" ? ClickStaffLevels :
            SelectedPage?.HubName == "snap" ? SnapStaffLevels :
            OtherStaffLevels;

        private string staffLevel = "Mod";

        public string StaffLevel
        {
            get => staffLevel;
            set
            {
                if (Set(ref staffLevel, value))
                {
                    UpdateScript();
                }
            }
        }

        #endregion

        #region Manual placeholder

        private string manualPlaceholderKey = "";
        public string ManualPlaceholderKey
        {
            get => manualPlaceholderKey;
            set => SetWithCommandsWithParameter(ref manualPlaceholderKey, value, [InsertManualPlaceholderCommand]);
        }

        #endregion

        #region Clipboard support

        public void CopyTextToClipboard(string text, string title, string successMessage)
        {
            if (TrySetClipboardText(text))
            {
                notificationManager.Show(
                    title,
                    successMessage,
                    type: NotificationType.Information,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                notificationManager.Show(
                    title + " failed",
                    "Could not copy text to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(12));
            }
        }

        public static bool TrySetClipboardText(string text)
        {
            const uint CLIPBRD_E_CANT_OPEN = 0x800401D0;
            var retriesLeft = 9;
            while (retriesLeft >= 0)
            {
                try
                {
                    Clipboard.Clear();
                    Clipboard.SetText(text);
                    return true;
                }
                catch (COMException ex)
                {
                    Logger.LogError($"Failed to copy text to clipboard: {ex.Message}");
                    Logger.LogError(ex.ToString());
                    if ((uint)ex.ErrorCode != CLIPBRD_E_CANT_OPEN)
                    {
                        throw;
                    }
                    --retriesLeft;
                    Thread.Sleep((9 - retriesLeft) * 10);
                }
            }
            return false;
        }

        #endregion

        #region Commands

        public CommandWithParameter ReloadPagesCatalogCommand { get; }
        private async void ReloadPages(object? ignoreDirty)
        {
            Logger.LogInfo("Execute ReloadPagesCatalogCommand");
            if (IsDirty && ignoreDirty == null)
            {
                var result = await HandleDirtyAction(MainWindow!, "Reload", "Are you sure you wish to reload the pages?");
                switch (result)
                {
                    case DirtyActionResult.Confirm:
                        ReloadPagesCatalogCommand?.Execute(true);
                        break;
                    case DirtyActionResult.CopyReport:
                        {
                            var report = GenerateReport();
                            if (!string.IsNullOrEmpty(report))
                            {
                                CopyTextToClipboard(report, "Report generated", "The report has been copied to the clipboard");
                                Logger.LogInfo("Generated report and copied to clipboard");
                            }
                            ReloadPagesCatalogCommand?.Execute(true);
                        }
                        break;
                    case DirtyActionResult.SaveReport:
                        {
                            var report = GenerateReport();
                            if (string.IsNullOrEmpty(report))
                            {
                                ReloadPagesCatalogCommand?.Execute(true);
                            }
                            else if (SaveReport(report))
                            {
                                Logger.LogInfo("Generated report and saved to file");
                                ReloadPagesCatalogCommand?.Execute(true);
                            }
                        }
                        break;
                }
                return;
            }
            SelectedTemplate = null;
            SelectedPage = null;

            await LoadPages(true);
        }

        public Command CopyReportCommand { get; }

        public Command SaveReportCommand { get; }

        public bool SaveReport(string report)
        {
            SaveFileDialog dialog = new()
            {
                Filter = "Text files (*.txt)|*.txt|All files (*.*)|*.*",
                Title = "Save the report to a file",
                OverwritePrompt = true,
                FileName = $"Change report - {DateTime.Now:yyyy-MM-dd}.txt",
            };
            if (dialog.ShowDialog() == true)
            {
                try
                {
                    File.WriteAllText(dialog.FileName, report);
                    notificationManager.Show(
                        "Saved the report",
                        "The report has been saved to the file",
                        type: NotificationType.Information,
                        areaName: "WindowArea",
                        expirationTime: TimeSpan.FromSeconds(3));
                    return true;
                }
                catch (Exception ex)
                {
                    Logger.LogError($"Failed to save the report: {ex.Message}");
                    Logger.LogError(ex.ToString());
                    ShowErrorToast(
                        "Failed to save the report",
                        "The application failed to save the report to the selected file: " + ex.Message,
                        NotificationType.Error, 
                        () => { });
                }
            }
            return false;
        }

        public string GenerateReport()
        {
            Logger.LogInfo("Execute CopyReportCommand");
            if (SelectedPage != null)
            {
                var builder = new StringBuilder();
                builder.AppendLine("REPORT OF CHANGES");
                builder.AppendLine("");
                
                foreach (var page in Catalog!.Pages)
                {
                    if (page.IsDirty)
                    {
                        // TODO andydragon : currently nothing can be dirty in a page?
                        Logger.LogWarning("Page cannot be dirty yet");
                    }
                }

                foreach (var templatePage in Catalog!.TemplatePages)
                {
                    var page = Catalog.Pages.FirstOrDefault(page => page.Id == templatePage.Name);
                    if (templatePage.IsDirty && page != null)
                    {
                        builder.AppendLine("-----------------");
                        builder.AppendLine($"PAGE: '{page.DisplayName}'");

                        var addedTemplates = templatePage.AddedTemplates;
                        foreach (var template in templatePage.Templates)
                        {
                            if (template.IsDirty || template.IsNew)
                            {
                                if (template.IsNew && addedTemplates.Contains(template.Name))
                                {
                                    Logger.LogInfo($"Template '{template.Name}' for page '{page.DisplayName}' was added");
                                    builder.AppendLine("");
                                    builder.AppendLine($"    ADD TEMPLATE: '{template.Name}'");
                                    builder.AppendLine("    ---");
                                    builder.AppendLine("        " + template.Template.Replace("\n", "\n        "));
                                    builder.AppendLine("    ---");
                                }
                                else
                                {
                                    Logger.LogInfo($"Template '{template.Name}' for page '{page.DisplayName}' was changed");
                                    builder.AppendLine("");
                                    builder.AppendLine($"    MODIFY TEMPLATE: '{template.Name}'");
                                    builder.AppendLine("    ---");
                                    builder.AppendLine("        " + template.Template.Replace("\n", "\n        "));
                                    builder.AppendLine("    ---");
                                }
                            }
                        }

                        var removedTemplates = templatePage.RemovedTemplates;
                        foreach (var template in removedTemplates)
                        {
                            Logger.LogInfo($"Template '{template}' for page '{page.DisplayName}' was removed");
                            builder.AppendLine("");
                            builder.AppendLine($"    REMOVE TEMPLATE: '{template}'");
                        }
                    }
                }

                builder.AppendLine("------------------");

                return builder.ToString();
            }
            return "";
        }

        public Command AddNewTemplateCommand { get; }
        private void AddNewTemplate()
        {
            Logger.LogInfo($"Execute AddNewTemplateCommand for {SelectedNewTemplate!}");
            if (Catalog != null && SelectedPage != null)
            {
                var templatePage = Catalog.TemplatePages.FirstOrDefault(page => page.Name == SelectedPage.Id);
                SelectedTemplate = templatePage?.AddTemplate(SelectedNewTemplate!);
                OnPropertyChanged(nameof(NewTemplates));
                SelectedNewTemplate = NewTemplates.FirstOrDefault();
            }
        }
        private bool CanAddNewTemplate()
        {
            return Catalog != null && SelectedPage != null && !string.IsNullOrEmpty(SelectedNewTemplate);
        }

        public Command CopyTemplateCommand { get; }
        private void CopyTemplate()
        {
            Logger.LogInfo($"Execute CopyTemplateCommand");
            if (TemplateTextEditor != null)
            {
                CopyTextToClipboard(TemplateTextEditor.Text, "Copied!", "Copied the script template to the clipboard");
            }
        }
        private bool CanCopyTemplate()
        {
            return TemplateTextEditor != null && !string.IsNullOrEmpty(TemplateTextEditor.Text);
        }

        public Command PasteTemplateCommand { get; }
        private void PasteTemplate()
        {
            Logger.LogInfo($"Execute PasteTemplateCommand");
            if (Clipboard.ContainsText())
            {
                PasteTemplateToEditor(Clipboard.GetText());
            }
        }

        public Command RevertTemplateCommand { get; }
        private void RevertTemplate()
        {
            Logger.LogInfo($"Execute RevertTemplateCommand");
            if (SelectedTemplate != null)
            {
                PasteTemplateToEditor(SelectedTemplate.OriginalTemplate ?? "");
            }
        }
        private bool CanRevertTemplate()
        {
            return TemplateTextEditor != null && SelectedTemplate != null && SelectedTemplate.IsDirty;
        }

        public Command RemoveTemplateCommand { get; }
        private void RemoveTemplate()
        {
            Logger.LogInfo($"Execute RemoveTemplateCommand");
            if (SelectedTemplate != null)
            {
                Catalog!.TemplatePages.FirstOrDefault(page => page.Name == SelectedPage!.Id)?.Templates.Remove(SelectedTemplate!);
                SelectedTemplate = null;
                OnPropertyChanged(nameof(NewTemplates));
            }
        }
        private bool CanRemoveTemplate()
        {
            return TemplateTextEditor != null && SelectedTemplate != null;
        }

        public CommandWithParameter InsertStaticPlaceholderCommand { get; }
        private void InsertStaticPlaceholder(object? parameter)
        {
            Logger.LogInfo($"Execute InsertStaticPlaceholderCommand");
            if (parameter is string placeholder)
            {
                PasteTextToSelection($"%%{placeholder.ToUpper()}%%");
            }
        }

        public CommandWithParameter InsertManualPlaceholderCommand { get; }
        private void InsertManualPlaceholder(object? parameter)
        {
            if (Convert.ToBoolean(parameter))
            {
                Logger.LogInfo($"Execute InsertManualPlaceholderCommand (long)");
                PasteTextToSelection($"[{{{ManualPlaceholderKey}}}]");
            }
            else
            {
                Logger.LogInfo($"Execute InsertManualPlaceholderCommand (short)");
                PasteTextToSelection($"[[{ManualPlaceholderKey}]]");
            }
        }
        private bool CanInsertManualPlaceholder(object? parameter)
        {
            return !string.IsNullOrEmpty(ManualPlaceholderKey);
        }

        public Command CopyScriptCommand { get; }
        private void CopyScript()
        {
            Logger.LogInfo($"Execute CopyScriptCommand");
            if (CheckForPlaceholders())
            {
                var editor = new PlaceholderEditor(this)
                {
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner,
                };
                editor.ShowDialog();
            }
            else
            {
                CopyTextToClipboard(Script, "Copied!", "Copied the sample script to the clipboard");
            }
        }

        public ICommand SetThemeCommand { get; }
        private void SetTheme(object? parameter)
        {
            if (parameter is Theme theme)
            {
                Theme = theme;
            }
        }

        public ICommand LaunchAboutCommand { get; }
        private void LaunchAbout()
        {
            var panel = new AboutDialog
            {
                DataContext = new AboutViewModel(),
                Owner = Application.Current.MainWindow,
                WindowStartupLocation = WindowStartupLocation.CenterOwner
            };
            panel.ShowDialog();
        }

        #endregion

        #region Placeholder management

        public ObservableCollection<Placeholder> PlaceholdersMap { get; } = [];
        public ObservableCollection<Placeholder> LongPlaceholdersMap { get; } = [];

        private void ClearAllPlaceholders()
        {
            PlaceholdersMap.Clear();
            LongPlaceholdersMap.Clear();
        }

        public bool ScriptHasPlaceholder()
        {
            return PlaceholderRegex().Matches(Script).Count != 0 || LongPlaceholderRegex().Matches(Script).Count != 0;
        }

        public bool CheckForPlaceholders()
        {
            var needEditor = false;

            var placeholders = new List<string>();
            var matches = PlaceholderRegex().Matches(Script);
            foreach (Match match in matches.Cast<Match>())
            {
                placeholders.Add(match.Captures.First().Value.Trim(['[', ']']));
            }
            if (placeholders.Count != 0)
            {
                needEditor = true;
                foreach (var placeholderName in placeholders)
                {
                    if (PlaceholdersMap.FirstOrDefault(placeholder => placeholder.Name == placeholderName) == null)
                    {
                        PlaceholdersMap.Add(new Placeholder(placeholderName, ""));
                    }
                }
            }

            var longPlaceholders = new List<string>();
            var longMatches = LongPlaceholderRegex().Matches(Script);
            foreach (Match match in longMatches.Cast<Match>())
            {
                longPlaceholders.Add(match.Captures.First().Value.Trim(['[', '{', '}', ']']));
            }
            if (longPlaceholders.Count != 0)
            {
                needEditor = true;
                foreach (var longPlaceholderName in longPlaceholders)
                {
                    if (LongPlaceholdersMap.FirstOrDefault(longPlaceholder => longPlaceholder.Name == longPlaceholderName) == null)
                    {
                        LongPlaceholdersMap.Add(new Placeholder(longPlaceholderName, ""));
                    }
                }
            }
            if (placeholders.Count != 0 || longPlaceholders.Count != 0)
            {
                Logger.LogInfo("Script contained placeholders, opening editor");
                return needEditor;
            }
            return false;
        }

        public string ProcessPlaceholders()
        {
            var result = Script;
            foreach (var placeholder in PlaceholdersMap)
            {
                result = result.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim());
            }
            foreach (var longPlaceholder in LongPlaceholdersMap)
            {
                result = result.Replace("[{" + longPlaceholder.Name + "}]", longPlaceholder.Value.Trim());
            }
            return result;
        }

        public void CopyScriptFromPlaceholders(bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                CopyTextToClipboard(Script, "Copied!", "Copied the sample script with placeholders to the clipboard");
            }
            else
            {
                CopyTextToClipboard(ProcessPlaceholders(), "Copied!", "Copied the sample script to the clipboard");
            }
        }

        #endregion

        internal void UpdateScript(bool setFromEditor = true)
        {
            ClearAllPlaceholders();
            if (SelectedTemplate != null && SelectedPage != null)
            {
                if (setFromEditor && TemplateTextEditor != null)
                {
                    SelectedTemplate.Template = TemplateTextEditor.Text;
                }
                var currentPageDisplayName = SelectedPage.Name;
                var scriptPageName = SelectedPage.PageName ?? currentPageDisplayName;
                var scriptPageHash = SelectedPage.HashTag ?? currentPageDisplayName;
                var scriptPageTitle = SelectedPage.Title ?? currentPageDisplayName;
                var membershipString = (SelectedPage?.HubName == "snap" && Membership.StartsWith("Snap ")) ? Membership[5..] : Membership;
                Script = SelectedTemplate.Template
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", currentPageDisplayName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", membershipString)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
            }
            else
            {
                Script = "";
            }
        }

        #region Toasts

        internal void ShowToast(string title, string? message, NotificationType type, TimeSpan? expirationTime = null)
        {
            notificationManager.Show(
                title,
                message,
                type: type,
                areaName: "WindowArea",
                expirationTime: expirationTime);
        }

        internal async void ShowErrorToast(string title, string? message, NotificationType type, Action action)
        {
            int sleepTime = 0;
            int MaxSleepTime = 1000 * 60 * 60;
            int SleepStep = 500;

            while (sleepTime < MaxSleepTime)
            {
                if (MainWindow != null && MainWindow.IsVisible)
                {
                    var wasClicked = false;
                    notificationManager.Show(
                        title,
                        message,
                        type,
                        areaName: "WindowArea",
                        onClick: () =>
                        {
                            wasClicked = true;
                            action();
                        },
                        ShowXbtn: true,
                        onClose: () =>
                        {
                            if (!wasClicked)
                            {
                                MainWindow?.Close();
                            }
                        },
                        expirationTime: TimeSpan.MaxValue);
                    break;
                }
                sleepTime += SleepStep;
                await Task.Delay(SleepStep);
            }
        }

        #endregion

        [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
        private static partial Regex PlaceholderRegex();

        [GeneratedRegex("\\[\\{([^\\}]*)\\}\\]")]
        private static partial Regex LongPlaceholderRegex();
    }

    public class ThemeOption(Theme theme, bool isSelected = false)
    {
        public Theme Theme { get; } = theme;

        public bool IsSelected { get; } = isSelected;
    }
}
