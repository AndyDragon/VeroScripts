using ControlzEx.Theming;
using Newtonsoft.Json;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Runtime.InteropServices;
using System.Security.Principal;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;
using System.Windows.Media;

namespace VeroScripts
{
    public enum Script
    {
        Feature = 1,
        Comment,
        OriginalPost,
    }

    public partial class MainViewModel : NotifyPropertyChanged
    {
        #region Field validation

        public static ValidationResult ValidateUser(string hubName, string userName)
        {
            var userNameValidationResult = ValidateUserName(userName);
            if (!userNameValidationResult.IsValid)
            {
                return userNameValidationResult;
            }
            if (DisallowLists.TryGetValue(hubName, out List<string>? disallowList) &&
                disallowList.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null)
            {
                return new ValidationResult(ValidationResultType.Error, "User is on the disallow list");
            }
            if (CautionLists.TryGetValue(hubName, out List<string>? cautionList) &&
                cautionList.FirstOrDefault(caution => string.Equals(caution, userName, StringComparison.OrdinalIgnoreCase)) != null)
            {
                return new ValidationResult(ValidationResultType.Warning, "User is on the caution list");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        public static ValidationResult ValidateValueNotEmpty(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return new ValidationResult(ValidationResultType.Error, "Required value");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        public static ValidationResult ValidateValueNotDefault(string value, string defaultValue)
        {
            if (string.IsNullOrEmpty(value) || string.Equals(value, defaultValue, StringComparison.OrdinalIgnoreCase))
            {
                return new ValidationResult(ValidationResultType.Error, "Required value");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        public static ValidationResult ValidateUserName(string userName)
        {
            if (string.IsNullOrEmpty(userName))
            {
                return new ValidationResult(ValidationResultType.Error, "Required value");
            }
            if (userName.StartsWith('@'))
            {
                return new ValidationResult(ValidationResultType.Error, "Don't include the '@' in user names");
            }
            if (userName.Contains('\n') || userName.Contains('\r'))
            {
                return new ValidationResult(ValidationResultType.Error, "Value cannot contain newline");
            }
            if (userName.Contains(' '))
            {
                return new ValidationResult(ValidationResultType.Error, "Value cannot contain spaces");
            }
            if (userName.Length <= 1)
            {
                return new ValidationResult(ValidationResultType.Error, "User name should be more than 1 character long");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        internal static ValidationResult ValidateValueNotEmptyAndContainsNoNewlines(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return new ValidationResult(ValidationResultType.Error, "Required value");
            }
            if (value.Contains('\n') || value.Contains('\r'))
            {
                return new ValidationResult(ValidationResultType.Error, "Value cannot contain newline");
            }
            return new ValidationResult(ValidationResultType.Valid);
        }

        #endregion

        private readonly HttpClient httpClient = new();
        private readonly NotificationManager notificationManager = new();
        private readonly Dictionary<Script, string> scriptNames = new()
        {
            { Script.Feature, "feature" },
            { Script.Comment, "comment" },
            { Script.OriginalPost, "original post" },
        };

        public MainViewModel()
        {
            _ = LoadPages();
            TemplatesCatalog = new TemplatesCatalog();
            Scripts = new Dictionary<Script, string>
            {
                { Script.Feature, "" },
                { Script.Comment, "" },
                { Script.OriginalPost, "" }
            };
            PlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
            {
                { Script.Feature, new ObservableCollection<Placeholder>() },
                { Script.Comment, new ObservableCollection<Placeholder>() },
                { Script.OriginalPost, new ObservableCollection<Placeholder>() }
            };
            LongPlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
            {
                { Script.Feature, new ObservableCollection<Placeholder>() },
                { Script.Comment, new ObservableCollection<Placeholder>() },
                { Script.OriginalPost, new ObservableCollection<Placeholder>() }
            };
            ClearUserCommand = new Command(ClearUser);
            LoadPhotosCommand = new Command(() =>
            {
                LoadedPost = new DownloadedPostViewModel(this);
                View = ViewMode.PostDownloaderView;

            }, () => !string.IsNullOrEmpty(PostLink));
            CloseCurrentViewCommand = new Command(() =>
            {
                View = View switch
                {
                    ViewMode.PostDownloaderView => ViewMode.ScriptView,
                    ViewMode.ImageView => ViewMode.PostDownloaderView,
                    ViewMode.ImageValidationView => ViewMode.PostDownloaderView,
                    _ => ViewMode.ScriptView,
                };
            });
            CopyFeatureScriptCommand = new Command(() => CopyScript(Script.Feature, force: true));
            CopyFeatureScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.Feature, force: true, withPlaceholders: true));
            CopyCommentScriptCommand = new Command(() => CopyScript(Script.Comment, force: true));
            CopyCommentScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.Comment, force: true, withPlaceholders: true));
            CopyOriginalPostScriptCommand = new Command(() => CopyScript(Script.OriginalPost, force: true));
            CopyOriginalPostScriptWithPlaceholdersCommand = new Command(() => CopyScript(Script.OriginalPost, force: true, withPlaceholders: true));
            CopyNewMembershipScriptCommand = new Command(CopyNewMembershipScript);
            SetThemeCommand = new CommandWithParameter((parameter) =>
            {
                if (parameter is Theme theme)
                {
                    Theme = theme;
                }
            });
            LaunchAboutCommand = new Command(() =>
            {
                var panel = new AboutDialog
                {
                    DataContext = new AboutViewModel(),
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner
                };
                panel.ShowDialog();
            });
        }

        #region User settings

        public static string GetDataLocationPath()
        {
            var user = WindowsIdentity.GetCurrent();
            var dataLocationPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AndyDragonSoftware",
                "FeatureLogging",
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

        private async Task LoadPages()
        {
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var pagesUri = new Uri("https://vero.andydragon.com/static/data/pages.json");
                var content = await httpClient.GetStringAsync(pagesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    var scriptsCatalog = JsonConvert.DeserializeObject<ScriptsCatalog>(content) ?? new ScriptsCatalog();
                    var loadedHubManifests = new Dictionary<string, HubManifestEntry>();
                    if (scriptsCatalog.HubManifests != null)
                    {
                        foreach (var hubPair in scriptsCatalog.HubManifests)
                        {
                            loadedHubManifests.Add(hubPair.Key, hubPair.Value);
                        }
                    }
                    LoadedHubManifests.Clear();
                    foreach (var hubManifest in loadedHubManifests.OrderBy(hub => hub.Key))
                    {
                        LoadedHubManifests.Add(hubManifest.Value);
                    }
                    var loadedPages = new List<LoadedPage>();
                    if (scriptsCatalog.Hubs != null)
                    {
                        foreach (var hubPair in scriptsCatalog.Hubs)
                        {
                            foreach (var hubPage in hubPair.Value)
                            {
                                loadedPages.Add(new LoadedPage(hubPair.Key, hubPage));
                            }
                        }
                    }
                    LoadedPages.Clear();
                    foreach (var page in loadedPages.OrderBy(page => page, LoadedPageComparer.Default))
                    {
                        LoadedPages.Add(page);
                    }
                    ShowToast(
                        "Pages loaded",
                        "Loaded " + LoadedPages.Count.ToString() + " pages from the server",
                        type: NotificationType.Information,
                        expirationTime: TimeSpan.FromSeconds(3));
                }
                _ = LoadTemplates();
                _ = LoadDisallowAndCautionLists();
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error occurred: {0}", ex.Message);
                ShowErrorToast(
                    "Failed to load the page catalog",
                    "The application requires the catalog to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadPages(); });
            }
        }

        private async Task LoadTemplates()
        {
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var templatesUri = new Uri("https://vero.andydragon.com/static/data/templates.json");
                var content = await httpClient.GetStringAsync(templatesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    TemplatesCatalog = JsonConvert.DeserializeObject<TemplatesCatalog>(content) ?? new TemplatesCatalog();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine("Error occurred: {0}", ex.Message);
                ShowErrorToast(
                    "Failed to load the page templates",
                    "The application requires the templtes to perform its operations: " + ex.Message + "\n\nClick here to retry",
                    NotificationType.Error,
                    () => { _ = LoadTemplates(); });
            }
        }

        private async Task LoadDisallowAndCautionLists()
        {
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var disallowedListsUri = new Uri("https://vero.andydragon.com/static/data/disallowlists.json");
                var disallowListsContent = await httpClient.GetStringAsync(disallowedListsUri);
                if (!string.IsNullOrEmpty(disallowListsContent))
                {
                    disallowLists = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(disallowListsContent) ?? [];

                    var cautionListsUri = new Uri("https://vero.andydragon.com/static/data/cautionlists.json");
                    var cautionListsContent = await httpClient.GetStringAsync(cautionListsUri);
                    if (!string.IsNullOrEmpty(cautionListsContent))
                    {
                        cautionLists = JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(cautionListsContent) ?? [];
                    }
                }
                UserNameValidation = ValidateUser(SelectedPage?.HubName ?? "", UserName);
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
            catch (Exception ex)
            {
                // Do nothing, not vital
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
        }

        #endregion

        #region Commands

        public ICommand ClearUserCommand { get; }

        public Command PastePostLinkCommand => new(() => 
        {
            if (Clipboard.ContainsText())
            {
                var postLink = Clipboard.GetText().Trim();
                if (postLink.StartsWith("https://vero.co/"))
                {
                    PostLink = postLink;
                    var possibleUserAlias = postLink[16..].Split('/').FirstOrDefault() ?? "";
                    if (possibleUserAlias.Length > 1)
                    {
                        UserName = possibleUserAlias;
                        ShowToast(
                            "Found user name", 
                            "Parsed the user name from the post link", 
                            NotificationType.Success,
                            expirationTime: TimeSpan.FromSeconds(3));
                    }
                    else
                    {
                        ShowToast(
                            "User name not in VERO link", 
                            "Could not parse the user name from the VERO link, user might not have user name, use their name without spaces", 
                            NotificationType.Error,
                            expirationTime: TimeSpan.FromSeconds(12));
                    }
                }
                else
                {
                    ShowToast(
                        "Clipboard did not contain VERO link", 
                        "Could not parse the user name from the clipboard, the clipboard doesn't contain a VERO link", 
                        NotificationType.Error,
                        expirationTime: TimeSpan.FromSeconds(12));
                }
            }
        }, () => Clipboard.ContainsText());

        public Command LoadPhotosCommand { get; }

        public Command CloseCurrentViewCommand { get; }

        public ICommand CopyFeatureScriptCommand { get; }

        public ICommand CopyFeatureScriptWithPlaceholdersCommand { get; }

        public ICommand LaunchAboutCommand { get; }

        public ICommand CopyCommentScriptCommand { get; }

        public ICommand CopyCommentScriptWithPlaceholdersCommand { get; }

        public ICommand CopyOriginalPostScriptCommand { get; }

        public ICommand CopyOriginalPostScriptWithPlaceholdersCommand { get; }

        public ICommand CopyNewMembershipScriptCommand { get; }

        public ICommand SetThemeCommand { get; }

        #endregion

        #region View management

        public enum ViewMode { ScriptView, PostDownloaderView, ImageValidationView, ImageView }
        private ViewMode view = ViewMode.ScriptView;

        public ViewMode View
        {
            get => view;
            set
            {
                var oldView = view;
                if (Set(ref view, value))
                {
                    OnPropertyChanged(nameof(ScriptViewVisibility));
                    OnPropertyChanged(nameof(PostDownloaderViewVisibility));
                    OnPropertyChanged(nameof(ImageValidationViewVisibility));
                    OnPropertyChanged(nameof(ImageViewVisibility));
                    if (view != ViewMode.PostDownloaderView && view != ViewMode.ImageValidationView && view != ViewMode.ImageView)
                    {
                        LoadedPost = null;
                    }
                    switch(view)
                    {
                        default:
                            MainWindow!.PrepareFocusForView(view);
                            break;
                        case ViewMode.PostDownloaderView:
                            MainWindow!.PrepareFocusForView(view, oldView == ViewMode.ScriptView);
                            break;
                    }
                }
            }
        }

        public Visibility ScriptViewVisibility => view == ViewMode.ScriptView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility PostDownloaderViewVisibility => view == ViewMode.PostDownloaderView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility ImageValidationViewVisibility => view == ViewMode.ImageValidationView ? Visibility.Visible : Visibility.Collapsed;
        public Visibility ImageViewVisibility => view == ViewMode.ImageView ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        public TemplatesCatalog TemplatesCatalog { get; private set; }

        private static Dictionary<string, List<string>> disallowLists = [];
        public static Dictionary<string, List<string>> DisallowLists
        {
            get => disallowLists;
            set => disallowLists = value;
        }

        private static Dictionary<string, List<string>> cautionLists = [];
        public static Dictionary<string, List<string>> CautionLists
        {
            get => cautionLists;
            set => cautionLists = value;
        }

        private Theme? theme = ThemeManager.Current.DetectTheme();
        public Theme? Theme
        {
            get => theme;
            set
            {
                if (Set(ref theme, value))
                {
                    if (Theme != null)
                    {
                        ThemeManager.Current.ChangeTheme(Application.Current, Theme);
                        UserSettings.Store("theme", Theme.Name);
                        OnPropertyChanged(nameof(UserNameValidation));
                        OnPropertyChanged(nameof(MembershipValidation));
                        OnPropertyChanged(nameof(YourNameValidation));
                        OnPropertyChanged(nameof(YourFirstNameValidation));
                        OnPropertyChanged(nameof(PageValidation));
                        OnPropertyChanged(nameof(CanCopyScripts));
                        OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                        OnPropertyChanged(nameof(StatusBarBrush));
                        OnPropertyChanged(nameof(Themes));
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

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

        #region User name

        public void ClearUser()
        {
            UserName = "";
            Membership = "None";
            FirstForPage = false;
            RawTag = false;
            CommunityTag = false;
            NewMembership = "None";
            PostLink = "";
        }

        private string postLink = "";

        public string PostLink
        {
            get => postLink;
            set
            {
                if (Set(ref postLink, value))
                {
                    LoadPhotosCommand.OnCanExecuteChanged();
                    OnPropertyChanged(nameof(PostLinkValidation));
                }
            }
        }

        public ValidationResult PostLinkValidation => ValidateValueNotEmpty(PostLink);

        private string userName = "";

        public string UserName
        {
            get => userName;
            set
            {
                if (Set(ref userName, value))
                {
                    UserNameValidation = ValidateUser(SelectedPage?.HubName ?? "", UserName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult userNameValidation = ValidateUser("", "");

        public ValidationResult UserNameValidation
        {
            get => userNameValidation;
            private set
            {
                if (Set(ref userNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Membership level

        private static string[] SnapMemberships => [
            "None",
            "Artist",
            "Snap Member",
            "Snap VIP Member",
            "Snap VIP Gold Member",
            "Snap Platinum Member",
            "Snap Elite Member",
            "Snap Hall of Fame Member",
            "Snap Diamond Member",
        ];

        private static string[] ClickMemberships => [
            "None",
            "Artist",
            "Click Member",
            "Click Bronze Member",
            "Click Silver Member",
            "Click Gold Member",
            "Click Platinum Member",
        ];

        private static string[] OtherMemberships => [
            "None",
            "Artist",
        ];

        public string[] HubMemberships => 
            SelectedPage?.HubName == "click" ? ClickMemberships : 
            SelectedPage?.HubName == "snap" ? SnapMemberships :
            OtherMemberships;

        private string membership = "None";

        public string Membership
        {
            get => membership;
            set
            {
                if (Set(ref membership, value))
                {
                    MembershipValidation = ValidateValueNotDefault(Membership, "None");
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult membershipValidation = ValidateValueNotDefault("None", "None");

        public ValidationResult MembershipValidation
        {
            get => membershipValidation;
            private set
            {
                if (Set(ref membershipValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Your name

        private string yourName = UserSettings.Get(nameof(YourName), "");

        public string YourName
        {
            get => yourName;
            set
            {
                if (Set(ref yourName, value))
                {
                    UserSettings.Store(nameof(YourName), YourName);
                    YourNameValidation = ValidateUserName(YourName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourNameValidation = ValidateUserName(UserSettings.Get(nameof(YourName), ""));

        public ValidationResult YourNameValidation
        {
            get => yourNameValidation;
            private set
            {
                if (Set(ref yourNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Your first name

        private string yourFirstName = UserSettings.Get(nameof(YourFirstName), "");

        public string YourFirstName
        {
            get => yourFirstName;
            set
            {
                if (Set(ref yourFirstName, value))
                {
                    UserSettings.Store(nameof(YourFirstName), YourFirstName);
                    YourFirstNameValidation = ValidateValueNotEmpty(YourFirstName);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourFirstNameValidation = ValidateUserName(UserSettings.Get(nameof(YourFirstName), ""));

        public ValidationResult YourFirstNameValidation
        {
            get => yourFirstNameValidation;
            private set
            {
                if (Set(ref yourFirstNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Pages

        public ObservableCollection<HubManifestEntry> LoadedHubManifests { get; } = [];

        public double AiWarningLimit
        {
            get
            {
                if (selectedHubManifest == null)
                {
                    return 0.75;
                }
                return selectedHubManifest.AiWarningLimit;
            }
        }

        public double AiTriggerLimit
        {
            get
            {
                if (selectedHubManifest == null)
                {
                    return 0.9;
                }
                return selectedHubManifest.AiTriggerLimit;
            }
        }

        public ObservableCollection<LoadedPage> LoadedPages { get; } = [];

        private HubManifestEntry? selectedHubManifest = null;
        private LoadedPage? selectedPage = null;

        public LoadedPage? SelectedPage
        {
            get => selectedPage;
            set
            {
                var oldHubName = SelectedPage?.HubName;
                if (Set(ref selectedPage, value))
                {
                    Page = SelectedPage?.Id ?? string.Empty;
                    if (oldHubName != SelectedPage?.HubName)
                    {
                        Membership = "None";
                        OnPropertyChanged(nameof(HubMemberships));
                        OnPropertyChanged(nameof(ClickHubVisibility));
                        OnPropertyChanged(nameof(SnapHubVisibility));
                        NewMembership = "None";
                        OnPropertyChanged(nameof(HubNewMemberships));
                        OnPropertyChanged(nameof(StaffLevels));
                        if (!StaffLevels.Contains(StaffLevel))
                        {
                            StaffLevel = StaffLevels[0];
                        }
                        UserNameValidation = ValidateUser(SelectedPage?.HubName ?? "", UserName);
                        if (SelectedPage != null)
                        {
                            excludedTags = UserSettings.Get(nameof(ExcludedTags) + ":" + SelectedPage.Id, "");
                        }
                        else
                        {
                            excludedTags = "";
                        }
                        OnPropertyChanged(nameof(ExcludedTags));
                    }
                    selectedHubManifest = LoadedHubManifests.FirstOrDefault(hub => hub.Hub == SelectedPage?.HubName);
                }
            }
        }
        public Visibility ClickHubVisibility => SelectedPage?.HubName == "click" ? Visibility.Visible : Visibility.Collapsed;
        public Visibility SnapHubVisibility => SelectedPage?.HubName == "snap" ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Page

        private static ValidationResult CalculatePageValidation(string page)
        {
            return ValidateValueNotEmpty(page);
        }

        static string FixPageHub(string page)
        {
            var parts = page.Split(':', 2);
            if (parts.Length > 1)
            {
                return page;
            }
            return "snap:" + page;
        }

        private string page = FixPageHub(UserSettings.Get(nameof(Page), ""));

        public string Page
        {
            get => page;
            set
            {
                if (Set(ref page, value))
                {
                    UserSettings.Store(nameof(Page), Page);
                    PageValidation = CalculatePageValidation(Page);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult pageValidation = CalculatePageValidation(UserSettings.Get(nameof(Page), ""));

        public ValidationResult PageValidation
        {
            get => pageValidation;
            private set
            {
                if (Set(ref pageValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    UpdateScripts();
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

        private string staffLevel = UserSettings.Get(nameof(StaffLevel), "Mod");

        public string StaffLevel
        {
            get => staffLevel;
            set
            {
                if (Set(ref staffLevel, value))
                {
                    UserSettings.Store(nameof(StaffLevel), StaffLevel);
                    ClearAllPlaceholders();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private string excludedTags = "";
        public string ExcludedTags
        {
            get => excludedTags;
            set
            {
                if (Set(ref excludedTags, value))
                {
                    if (SelectedPage != null)
                    {
                        UserSettings.Store(nameof(ExcludedTags) + ":" + SelectedPage.Id, ExcludedTags);
                    }
                    LoadedPost?.UpdateExcludedTags();
                }
            }
        }

        #endregion

        #region First for page

        private bool firstForPage = false;

        public bool FirstForPage
        {
            get => firstForPage;
            set
            {
                if (Set(ref firstForPage, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region RAW tag

        private bool rawTag = false;

        public bool RawTag
        {
            get => rawTag;
            set
            {
                if (Set(ref rawTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Community tag

        private bool communityTag = false;

        public bool CommunityTag
        {
            get => communityTag;
            set
            {
                if (Set(ref communityTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Hub tag

        private bool hubTag = false;

        public bool HubTag
        {
            get => hubTag;
            set
            {
                if (Set(ref hubTag, value))
                {
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        #endregion

        #region Feature script

        public Dictionary<Script, string> Scripts { get; private set; }

        public string FeatureScript
        {
            get => Scripts[Script.Feature];
            set
            {
                if (Scripts[Script.Feature] != value)
                {
                    Scripts[Script.Feature] = value;
                    OnPropertyChanged(nameof(FeatureScript));
                    OnPropertyChanged(nameof(FeatureScriptPlaceholderVisibility));
                    OnPropertyChanged(nameof(FeatureScriptLength));
                }
            }
        }

        public int FeatureScriptLength => FeatureScript.Length;

        public Visibility FeatureScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Feature) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Comment script

        public string CommentScript
        {
            get => Scripts[Script.Comment];
            set
            {
                if (Scripts[Script.Comment] != value)
                {
                    Scripts[Script.Comment] = value;
                    OnPropertyChanged(nameof(CommentScript));
                    OnPropertyChanged(nameof(CommentScriptPlaceholderVisibility));
                    OnPropertyChanged(nameof(CommentScriptLength));

                }
            }
        }

        public int CommentScriptLength => CommentScript.Length;

        public Visibility CommentScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.Comment) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region Original post script

        public string OriginalPostScript
        {
            get => Scripts[Script.OriginalPost];
            set
            {
                if (Scripts[Script.OriginalPost] != value)
                {
                    Scripts[Script.OriginalPost] = value;
                    OnPropertyChanged(nameof(OriginalPostScript));
                    OnPropertyChanged(nameof(OriginalPostScriptPlaceholderVisibility));
                    OnPropertyChanged(nameof(OriginalPostScriptLength));
                }
            }
        }

        public int OriginalPostScriptLength => OriginalPostScript.Length;

        public Visibility OriginalPostScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.OriginalPost) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region New membership level

        private static string[] SnapNewMemberships => [
            "None",
            "Member (feature comment)",
            "Member (original post comment)",
            "VIP Member (feature comment)",
            "VIP Member (original post comment)",
        ];

        private static string[] ClickNewMemberships => [
            "None",
            "Member",
            "Bronze Member",
            "Silver Member",
            "Gold Member",
            "Platinum Member",
        ];

        private static string[] OtherNewMemberships => [
            "None",
        ];

        public string[] HubNewMemberships => 
            SelectedPage?.HubName == "click" ? ClickNewMemberships : 
            SelectedPage?.HubName == "snap" ? SnapNewMemberships :
            OtherNewMemberships;

        private string newMembership = "None";

        public string NewMembership
        {
            get => newMembership;
            set
            {
                if (Set(ref newMembership, value))
                {
                    OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                    UpdateNewMembershipScripts();
                }
            }
        }

        private string newMembershipScript = "";

        public string NewMembershipScript
        {
            get => newMembershipScript;
            set => Set(ref newMembershipScript, value);
        }

        #endregion

        #region Placeholder management

        public Dictionary<Script, ObservableCollection<Placeholder>> PlaceholdersMap { get; private set; }
        public Dictionary<Script, ObservableCollection<Placeholder>> LongPlaceholdersMap { get; private set; }

        private void ClearAllPlaceholders()
        {
            PlaceholdersMap[Script.Feature].Clear();
            PlaceholdersMap[Script.Comment].Clear();
            PlaceholdersMap[Script.OriginalPost].Clear();
            LongPlaceholdersMap[Script.Feature].Clear();
            LongPlaceholdersMap[Script.Comment].Clear();
            LongPlaceholdersMap[Script.OriginalPost].Clear();
        }

        public bool ScriptHasPlaceholder(Script script)
        {
            return PlaceholderRegex().Matches(Scripts[script]).Count != 0 || LongPlaceholderRegex().Matches(Scripts[script]).Count != 0;
        }

        public bool CheckForPlaceholders(Script script, bool force = false)
        {
            var needEditor = false;

            var placeholders = new List<string>();
            var matches = PlaceholderRegex().Matches(Scripts[script]);
            foreach (Match match in matches.Cast<Match>())
            {
                placeholders.Add(match.Captures.First().Value.Trim(['[', ']']));
            }
            if (placeholders.Count != 0)
            {
                foreach (var placeholderName in placeholders)
                {
                    if (PlaceholdersMap[script].FirstOrDefault(placeholder => placeholder.Name == placeholderName) == null)
                    {
                        var placeholderValue = "";
                        foreach (var otherScript in Enum.GetValues<Script>())
                        {
                            if (otherScript != script)
                            {
                                var otherPlaceholder = PlaceholdersMap[otherScript].FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholderName);
                                if (otherPlaceholder != null && !string.IsNullOrEmpty(otherPlaceholder.Value))
                                {
                                    placeholderValue = otherPlaceholder.Value;
                                }
                            }
                        }
                        needEditor = true;
                        PlaceholdersMap[script].Add(new Placeholder(placeholderName, placeholderValue));
                    }
                }
            }

            var longPlaceholders = new List<string>();
            var longMatches = LongPlaceholderRegex().Matches(Scripts[script]);
            foreach (Match match in longMatches.Cast<Match>())
            {
                longPlaceholders.Add(match.Captures.First().Value.Trim(['[', '{', '}', ']']));
            }
            if (longPlaceholders.Count != 0)
            {
                foreach (var longPlaceholderName in longPlaceholders)
                {
                    if (LongPlaceholdersMap[script].FirstOrDefault(longPlaceholder => longPlaceholder.Name == longPlaceholderName) == null)
                    {
                        var longPlaceholderValue = "";
                        foreach (var otherScript in Enum.GetValues<Script>())
                        {
                            if (otherScript != script)
                            {
                                var otherLongPlaceholder = LongPlaceholdersMap[otherScript].FirstOrDefault(otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholderName);
                                if (otherLongPlaceholder != null && !string.IsNullOrEmpty(otherLongPlaceholder.Value))
                                {
                                    longPlaceholderValue = otherLongPlaceholder.Value;
                                }
                            }
                        }
                        needEditor = true;
                        LongPlaceholdersMap[script].Add(new Placeholder(longPlaceholderName, longPlaceholderValue));
                    }
                }
            }
            if (placeholders.Count != 0 || longPlaceholders.Count != 0) 
            {
                return needEditor || force;
            }
            return false;
        }

        internal void TransferPlaceholders(Script script)
        {
            foreach (var placeholder in PlaceholdersMap[script])
            {
                if (!string.IsNullOrEmpty(placeholder.Value))
                {
                    foreach (Script otherScript in Enum.GetValues(typeof(Script)))
                    {
                        if (otherScript != script)
                        {
                            var otherPlaceholder = PlaceholdersMap[otherScript].FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholder.Name);
                            if (otherPlaceholder != null)
                            {
                                otherPlaceholder.Value = placeholder.Value;
                            }
                        }
                    }
                }
            }
            foreach (var longPlaceholder in LongPlaceholdersMap[script])
            {
                if (!string.IsNullOrEmpty(longPlaceholder.Value))
                {
                    foreach (Script otherScript in Enum.GetValues(typeof(Script)))
                    {
                        if (otherScript != script)
                        {
                            var otherLongPlaceholder = LongPlaceholdersMap[otherScript].FirstOrDefault(otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholder.Name);
                            if (otherLongPlaceholder != null)
                            {
                                otherLongPlaceholder.Value = longPlaceholder.Value;
                            }
                        }
                    }
                }
            }
        }

        public string ProcessPlaceholders(Script script)
        {
            var result = Scripts[script];
            foreach (var placeholder in PlaceholdersMap[script])
            {
                result = result.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim());
            }
            foreach (var longPlaceholder in LongPlaceholdersMap[script])
            {
                result = result.Replace("[{" + longPlaceholder.Name + "}]", longPlaceholder.Value.Trim());
            }
            return result;
        }

        #endregion

        #region Script management

        public bool CanCopyScripts =>
            !UserNameValidation.IsError &&
            !MembershipValidation.IsError &&
            !YourNameValidation.IsError &&
            !YourFirstNameValidation.IsError &&
            !PageValidation.IsError;

        public bool CanCopyNewMembershipScript =>
            NewMembership != "None" &&
            !UserNameValidation.IsError;

        public MainWindow? MainWindow { get; internal set; }

        private void UpdateScripts()
        {
            var pageName = Page;
            var pageId = pageName;
            var scriptPageName = pageName;
            var scriptPageHash = pageName;
            var scriptPageTitle = pageName;
            var oldHubName = selectedPage?.HubName;
            var sourcePage = LoadedPages.FirstOrDefault(page => page.Id == Page);
            if (sourcePage != null)
            {
                pageId = sourcePage.Id;
                pageName = sourcePage.Name;
                scriptPageName = pageName;
                scriptPageHash = pageName;
                scriptPageTitle = pageName;
                if (sourcePage.PageName != null)
                {
                    scriptPageName = sourcePage.PageName;
                }
                if (sourcePage.Title != null)
                {
                    scriptPageTitle = sourcePage.Title;
                }
                if (sourcePage.HashTag != null)
                {
                    scriptPageHash = sourcePage.HashTag;
                }
            }
            SelectedPage = sourcePage;
            if (SelectedPage?.HubName != oldHubName) 
            {
                MembershipValidation = ValidateValueNotDefault(Membership, "None");
            }
            if (!CanCopyScripts)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.IsValid)
                    {
                        validationErrors += prefix + ": " + (result.Error ?? "unknown") + "\n";
                    }
                }

                CheckValidation("User", UserNameValidation);
                CheckValidation("Level", MembershipValidation);
                CheckValidation("You", YourNameValidation);
                CheckValidation("Your first name", YourFirstNameValidation);
                CheckValidation("Page:", PageValidation);

                FeatureScript = validationErrors;
                CommentScript = "";
                OriginalPostScript = "";
            }
            else
            {
                var featureScriptTemplate = GetTemplate("feature", pageId, FirstForPage, RawTag, CommunityTag);
                var commentScriptTemplate = GetTemplate("comment", pageId, FirstForPage, RawTag, CommunityTag);
                var originalPostScriptTemplate = GetTemplate("original post", pageId, FirstForPage, RawTag, CommunityTag);
                var membershipString = (SelectedPage?.HubName == "snap" && Membership.StartsWith("Snap ")) ? Membership[5..] : Membership;
                FeatureScript = featureScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", membershipString)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                CommentScript = commentScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", membershipString)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                OriginalPostScript = originalPostScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%MEMBERLEVEL%%", membershipString)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
            }
        }

        private string GetTemplate(
            string templateName,
            string pageName,
            bool firstForPage,
            bool rawTag,
            bool communityTag)
        {
            TemplateEntry? template = null;
            var templatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == pageName);

            // Check first feature and raw and community
            if (selectedPage?.HubName == "snap" && firstForPage && rawTag && communityTag)
            {
                template = templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw community " + templateName);
            }

            // Next check first feature and raw
            if (selectedPage?.HubName == "snap" && firstForPage && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw " + templateName);
            }

            // Next check first feature and community
            if (selectedPage?.HubName == "snap" && firstForPage && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first community " + templateName);
            }

            // Next check first feature
            if (firstForPage)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
            }

            // Next check raw and community
            if (selectedPage?.HubName == "snap" && rawTag && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw community " + templateName);
            }

            // Next check raw
            if (selectedPage?.HubName == "snap" && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw " + templateName);
            }

            // Next check community
            if (selectedPage?.HubName == "snap" && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
            }

            // Last check standard
            template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == templateName);

            return template?.Template ?? "";
        }

        private string GetNewMembershipScriptName(string hubName, string newMembershipLevel)
        {
            if (hubName == "snap")
            {
                return newMembershipLevel switch
                {
                    "Member (feature comment)" => "snap:member feature",
                    "Member (original post comment)" => "snap:member original post",
                    "VIP Member (feature comment)" => "snap:vip member feature",
                    "VIP Member (original post comment)" => "snap:vip member original post",
                    _ => "",
                };
            } else if (hubName == "click")
            {
                return hubName + ":" + NewMembership.Replace(" ", "_").ToLowerInvariant();
            }
            return "";
        }

        private void UpdateNewMembershipScripts()
        {
            if (!CanCopyNewMembershipScript)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.IsValid)
                    {
                        validationErrors += prefix + ": " + (result.Error ?? "unknown") + "\n";
                    }
                }

                if (newMembership != "None")
                {
                    CheckValidation("User", UserNameValidation);
                }

                NewMembershipScript = validationErrors;
            }
            else
            {
                var hubName = SelectedPage?.HubName;
                var pageName = Page;
                var pageId = pageName;
                var scriptPageName = pageName;
                var scriptPageHash = pageName;
                var scriptPageTitle = pageName;
                var sourcePage = LoadedPages.FirstOrDefault(page => page.Id == Page);
                if (sourcePage != null)
                {
                    pageId = sourcePage.Id;
                    pageName = sourcePage.Name;
                    scriptPageName = pageName;
                    scriptPageHash = pageName;
                    scriptPageTitle = pageName;
                    if (sourcePage.PageName != null)
                    {
                        scriptPageName = sourcePage.PageName;
                    }
                    if (sourcePage.Title != null)
                    {
                        scriptPageTitle = sourcePage.Title;
                    }
                    if (sourcePage.HashTag != null)
                    {
                        scriptPageHash = sourcePage.HashTag;
                    }
                }
                if (!string.IsNullOrEmpty(hubName))
                {
                    var templateName = GetNewMembershipScriptName(hubName, NewMembership);
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == templateName);
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
                else if (NewMembership == "Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
                else if (NewMembership == "VIP Member")
                {
                    TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member");
                    NewMembershipScript = (template?.Template ?? "")
                        .Replace("%%PAGENAME%%", scriptPageName)
                        .Replace("%%FULLPAGENAME%%", pageName)
                        .Replace("%%PAGETITLE%%", scriptPageTitle)
                        .Replace("%%PAGEHASH%%", scriptPageHash)
                        .Replace("%%USERNAME%%", UserName)
                        .Replace("%%YOURNAME%%", YourName)
                        .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                        .Replace("%%STAFFLEVEL%%", StaffLevel);
                }
            }
        }

        #endregion

        #region Clipboard management

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

        private void CopyTextToClipboard(string text, string successMessage)
        {
            if (TrySetClipboardText(text))
            {
                ShowToast(
                    "Copied script",
                    successMessage,
                    type: NotificationType.Success,
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                ShowToast(
                    "Failed to copy script",
                    "Could not copy script to the clipboard, if you have another clipping tool active, disable it and try again",
                    type: NotificationType.Error,
                    expirationTime: TimeSpan.FromSeconds(12));
            }
        }

        public void CopyScript(Script script, bool force = false, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                var unprocessedScript = Scripts[script];
                CopyTextToClipboard(unprocessedScript, "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else if (CheckForPlaceholders(script, force))
            {
                var editor = new PlaceholderEditor(this, script)
                {
                    Owner = Application.Current.MainWindow,
                    WindowStartupLocation = WindowStartupLocation.CenterOwner,
                };
                editor.ShowDialog();
            }
            else
            {
                var processedScript = ProcessPlaceholders(script);
                TransferPlaceholders(script);
                CopyTextToClipboard(processedScript, "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        public void CopyNewMembershipScript()
        {
            CopyTextToClipboard(NewMembershipScript, "Copied the new membership script to the clipboard");
        }

        public void CopyScriptFromPlaceholders(Script script, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                CopyTextToClipboard(Scripts[script], "Copied the " + scriptNames[script] + " script with placeholders to the clipboard");
            }
            else
            {
                TransferPlaceholders(script);
                CopyTextToClipboard(ProcessPlaceholders(script), "Copied the " + scriptNames[script] + " script to the clipboard");
            }
        }

        #endregion

        #region Loaded post

        private DownloadedPostViewModel? loadedPost;

        public DownloadedPostViewModel? LoadedPost
        {
            get => loadedPost;
            private set => Set(ref loadedPost, value, [nameof(TinEyeSource)]);
        }

        public string TinEyeSource { get => LoadedPost?.ImageValidation?.TinEyeUri ?? "about:blank"; }
        internal void TriggerTinEyeSource()
        {
            OnPropertyChanged(nameof(TinEyeSource));
        }

        #endregion

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
