using ControlzEx.Theming;
using Newtonsoft.Json;
using Notification.Wpf;
using System.Collections.ObjectModel;
using System.IO;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Security.Principal;
using System.Text.RegularExpressions;
using System.Windows;
using System.Windows.Input;

namespace VeroScripts
{
    public enum Script
    {
        Feature = 1,
        Comment,
        OriginalPost,
    }

    public partial class ScriptsViewModel : NotifyPropertyChanged
    {
        #region Field validation

        public static ValidationResult ValidateUser(string userName)
        {
            var userNameValidationResult = ValidateUserName(userName);
            if (!userNameValidationResult.Valid)
            {
                return userNameValidationResult;
            }
            if (disallowList.FirstOrDefault(disallow => string.Equals(disallow, userName, StringComparison.OrdinalIgnoreCase)) != null)
            {
                return new ValidationResult(false, "User is on the disallow list");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateValueNotEmpty(string value)
        {
            if (string.IsNullOrEmpty(value))
            {
                return new ValidationResult(false, "Required value");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateValueNotDefault(string value, string defaultValue)
        {
            if (string.IsNullOrEmpty(value) || string.Equals(value, defaultValue, StringComparison.OrdinalIgnoreCase))
            {
                return new ValidationResult(false, "Required value");
            }
            return new ValidationResult(true);
        }

        public static ValidationResult ValidateUserName(string userName)
        {
            if (string.IsNullOrEmpty(userName))
            {
                return new ValidationResult(false, "Required value");
            }
            if (userName.StartsWith('@'))
            {
                return new ValidationResult(false, "Don't include the '@' in user names");
            }
            return new ValidationResult(true);
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

        public ScriptsViewModel()
        {
            PagesCatalog = new PagesCatalog();
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
            ClearUserCommand = new Command(ClearUser);
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
        }

        private static string GetDataLocationPath()
        {
            var user = WindowsIdentity.GetCurrent();
            var dataLocationPath = Path.Combine(
                Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData),
                "AndyDragonSoftware",
                "VeroScripts",
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
                    PagesCatalog = JsonConvert.DeserializeObject<PagesCatalog>(content) ?? new PagesCatalog();
                    Pages = PagesCatalog.Pages.Select(page => page.Name).ToArray();
                    notificationManager.Show(
                        "Pages loaded",
                        "Loaded " + Pages.Length.ToString() + " pages from the server",
                        type: NotificationType.Information,
                        areaName: "WindowArea",
                        expirationTime: TimeSpan.FromSeconds(3));
                }
                _ = LoadTemplates();
                _ = LoadDisallowList();
            }
            catch (Exception ex)
            {
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
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
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
        }

        private async Task LoadDisallowList()
        {
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var templatesUri = new Uri("https://vero.andydragon.com/static/data/disallowlist.json");
                var content = await httpClient.GetStringAsync(templatesUri);
                if (!string.IsNullOrEmpty(content))
                {
                    disallowList = JsonConvert.DeserializeObject<List<string>>(content) ?? [];
                    OnPropertyChanged(nameof(UserNameValidation));
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
            catch (Exception ex)
            {
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
        }

        #endregion

        #region Commands

        public ICommand ClearUserCommand { get; }

        public ICommand CopyFeatureScriptCommand { get; }

        public ICommand CopyFeatureScriptWithPlaceholdersCommand { get; }

        public ICommand CopyCommentScriptCommand { get; }

        public ICommand CopyCommentScriptWithPlaceholdersCommand { get; }

        public ICommand CopyOriginalPostScriptCommand { get; }

        public ICommand CopyOriginalPostScriptWithPlaceholdersCommand { get; }

        public ICommand CopyNewMembershipScriptCommand { get; }

        public ICommand SetThemeCommand { get; }

        #endregion

        public PagesCatalog PagesCatalog { get; private set; }

        public TemplatesCatalog TemplatesCatalog { get; private set; }

        private static List<string> disallowList = [];

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
                    }
                }
            }
        }

        public ThemeOption[] Themes => [.. ThemeManager.Current.Themes.OrderBy(theme => theme.Name).Select(theme => new ThemeOption(theme, theme == Theme))];

        public static string Version => Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";

        #region User name

        public void ClearUser()
        {
            UserName = "";
            Membership = "None";
            FirstForPage = false;
            RawTag = false;
            CommunityTag = false;
            NewMembership = "None";
        }

        private string userName = "";

        public string UserName
        {
            get => userName;
            set
            {
                if (Set(ref userName, value))
                {
                    UserNameValidation = ValidateUser(UserName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult userNameValidation = ValidateUser("");

        public ValidationResult UserNameValidation
        {
            get => userNameValidation;
            private set
            {
                if (Set(ref userNameValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                    OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                }
            }
        }

        #endregion

        #region Membership level

        public static string[] Memberships => [
            "None",
            "Artist",
            "Member",
            "VIP Member",
            "VIP Gold Member",
            "Platinum Member",
            "Elite Member",
            "Hall of Fame Member",
            "Diamond Member",
        ];

        private string membership = "None";

        public string Membership
        {
            get => membership;
            set
            {
                if (Set(ref membership, value))
                {
                    MembershipValidation = ValidateValueNotDefault(Membership, "None");
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
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
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
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
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
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
                }
            }
        }

        #endregion

        #region Pages

        private string[] pages = [];

        public string[] Pages
        {
            get => pages;
            set
            {
                if (Set(ref pages, value))
                {
                    pages = value;
                    OnPropertyChanged(nameof(Page));
                    OnPropertyChanged(nameof(PageNameEnabled));
                    OnPropertyChanged(nameof(PageNameDisabled));
                }
            }
        }

        #endregion

        #region Page

        private static ValidationResult CalculatePageValidation(string page, string pageName)
        {
            if (string.IsNullOrEmpty(page) || string.Equals(page, "default", StringComparison.OrdinalIgnoreCase))
            {
                return ValidateValueNotEmpty(pageName);
            }
            return new ValidationResult(true);
        }

        private string page = UserSettings.Get(nameof(Page), "default");

        public string Page
        {
            get => page;
            set
            {
                if (Set(ref page, value))
                {
                    UserSettings.Store(nameof(Page), Page);
                    OnPropertyChanged(nameof(PageNameEnabled));
                    OnPropertyChanged(nameof(PageNameDisabled));
                    PageValidation = CalculatePageValidation(Page, PageName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                }
            }
        }

        private ValidationResult pageValidation = CalculatePageValidation(UserSettings.Get(nameof(Page), "default"), UserSettings.Get(nameof(PageName), ""));

        public ValidationResult PageValidation
        {
            get => pageValidation;
            private set
            {
                if (Set(ref pageValidation, value))
                {
                    OnPropertyChanged(nameof(CanCopyScripts));
                }
            }
        }

        public bool PageNameDisabled => !PageNameEnabled;
        public bool PageNameEnabled => Page == "default";

        private string pageName = UserSettings.Get(nameof(PageName), "");

        public string PageName
        {
            get => pageName;
            set
            {
                if (Set(ref pageName, value))
                {
                    UserSettings.Store(nameof(PageName), PageName);
                    PageValidation = CalculatePageValidation(Page, PageName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Staff level

        public static string[] StaffLevels => [
            "Mod",
            "Co-Admin",
            "Admin",
        ];

        private string staffLevel = UserSettings.Get(nameof(StaffLevel), "Mod");

        public string StaffLevel
        {
            get => staffLevel;
            set
            {
                if (Set(ref staffLevel, value))
                {
                    UserSettings.Store(nameof(StaffLevel), StaffLevel);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
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
                }
            }
        }

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
                }
            }
        }

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
                }
            }
        }

        public Visibility OriginalPostScriptPlaceholderVisibility => ScriptHasPlaceholder(Script.OriginalPost) ? Visibility.Visible : Visibility.Collapsed;

        #endregion

        #region New membership level

        public static string[] NewMemberships => [
            "None",
            "Member",
            "VIP Member",
        ];

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

        public bool ScriptHasPlaceholder(Script script)
        {
            return PlaceholderRegex().Matches(Scripts[script]).Count != 0;
        }

        public bool CheckForPlaceholders(Script script, bool force = false)
        {
            var placeholders = new List<string>();
            var matches = PlaceholderRegex().Matches(Scripts[script]);
            foreach (Match match in matches.Cast<Match>())
            {
                placeholders.Add(match.Captures.First().Value.Trim(['[', ']']));
            }
            if (placeholders.Count != 0)
            {
                var needEditor = false;
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
        }

        public string ProcessPlaceholders(Script script)
        {
            var result = Scripts[script];
            foreach (var placeholder in PlaceholdersMap[script])
            {
                result = result.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim());
            }
            return result;
        }

        #endregion

        #region Script management

        public bool CanCopyScripts =>
            UserNameValidation.Valid &&
            MembershipValidation.Valid &&
            YourNameValidation.Valid &&
            YourFirstNameValidation.Valid &&
            PageValidation.Valid;

        public bool CanCopyNewMembershipScript =>
            NewMembership != "None" &&
            UserNameValidation.Valid;

        private void UpdateScripts()
        {
            if (!CanCopyScripts)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.Valid)
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
                var pageName = Page == "default" || string.IsNullOrEmpty(Page) ? PageName : Page;
                var scriptPageName = pageName;
                if (Page != "default")
                {
                    var sourcePage = PagesCatalog.Pages.FirstOrDefault(page => page.Name == Page);
                    if (sourcePage != null && sourcePage.PageName != null)
                    {
                        scriptPageName = sourcePage.PageName;
                    }
                }
                var featureScriptTemplate = GetTemplate("feature", pageName, FirstForPage, RawTag, CommunityTag);
                var commentScriptTemplate = GetTemplate("comment", pageName, FirstForPage, RawTag, CommunityTag);
                var originalPostScriptTemplate = GetTemplate("original post", pageName, FirstForPage, RawTag, CommunityTag);
                FeatureScript = featureScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                CommentScript = commentScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                OriginalPostScript = originalPostScriptTemplate
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
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
            var defaultTemplatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == "default");
            var templatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == pageName);

            // Check first feature and raw and community
            if (firstForPage && rawTag && communityTag)
            {
                template = templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw community " + templateName);
            }

            // Next check first feature and raw
            if (firstForPage && rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first raw " + templateName);
            }

            // Next check first feature and community
            if (firstForPage && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first community " + templateName);
            }

            // Next check first feature
            if (firstForPage)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
            }

            // Next check raw and community
            if (rawTag && communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw community " + templateName);
            }

            // Next check raw
            if (rawTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "raw " + templateName);
            }

            // Next check community
            if (communityTag)
            {
                template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
            }

            // Last check standard
            template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == templateName);

            // Fallback to default
            template ??= defaultTemplatePage?.Templates.FirstOrDefault(template => template.Name == templateName);

            return template?.Template ?? "";
        }

        private void UpdateNewMembershipScripts()
        {
            if (!CanCopyNewMembershipScript)
            {
                var validationErrors = "";
                void CheckValidation(string prefix, ValidationResult result)
                {
                    if (!result.Valid)
                    {
                        validationErrors += prefix + ": " + (result.Error ?? "unknown") + "\n";
                    }
                }

                CheckValidation("User", UserNameValidation);

                NewMembershipScript = validationErrors;
            }
            else if (NewMembership == "Member")
            {
                TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member");
                NewMembershipScript = (template?.Template ?? "")
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName);
            }
            else if (NewMembership == "VIP Member")
            {
                TemplateEntry? template = TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member");
                NewMembershipScript = (template?.Template ?? "")
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName);
            }
        }

        #endregion

        #region Clipboard management

        public void CopyScript(Script script, bool force = false, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                var unprocessedScript = Scripts[script];
                Clipboard.SetText(unprocessedScript);
                notificationManager.Show(
                    "Copied script",
                    "Copied the " + scriptNames[script] + " script with placeholders to the clipboard",
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else if (CheckForPlaceholders(script, force))
            {
                var editor = new PlaceholderEditor(this, script)
                {
                    Owner = Application.Current.MainWindow,
                };
                editor.ShowDialog();
            }
            else
            {
                var processedScript = ProcessPlaceholders(script);
                TransferPlaceholders(script);
                Clipboard.SetText(processedScript);
                notificationManager.Show(
                    "Copied script",
                    "Copied the " + scriptNames[script] + " script to the clipboard",
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
        }

        public void CopyNewMembershipScript()
        {
            Clipboard.SetText(NewMembershipScript);
            notificationManager.Show(
                "Copied script",
                "Copied the new membership script to the clipboard",
                type: NotificationType.Success,
                areaName: "WindowArea",
                expirationTime: TimeSpan.FromSeconds(3));
        }

        public void CopyScriptFromPlaceholders(Script script, bool withPlaceholders = false)
        {
            if (withPlaceholders)
            {
                Clipboard.SetText(Scripts[script]);
                notificationManager.Show(
                    "Copied script",
                    "Copied the " + scriptNames[script] + " script with placeholders to the clipboard",
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
            else
            {
                TransferPlaceholders(script);
                Clipboard.SetText(ProcessPlaceholders(script));
                notificationManager.Show(
                    "Copied script",
                    "Copied the " + scriptNames[script] + " script to the clipboard",
                    type: NotificationType.Success,
                    areaName: "WindowArea",
                    expirationTime: TimeSpan.FromSeconds(3));
            }
        }

        #endregion

        [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
        private static partial Regex PlaceholderRegex();
    }

    public class ThemeOption(Theme theme, bool isSelected = false)
    {
        public Theme Theme { get; } = theme;

        public bool IsSelected { get; } = isSelected;
    }
}
