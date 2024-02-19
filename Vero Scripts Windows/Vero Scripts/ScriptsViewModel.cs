﻿using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Reflection;
using System.Text.Json;
using System.Text.RegularExpressions;
using System.Windows;
using Vero_Scripts.Properties;
using Notification.Wpf;

namespace Vero_Scripts
{
    public enum Script
    {
        Feature = 1,
        Comment,
        OriginalPost,
    }

    public partial class ScriptsViewModel : INotifyPropertyChanged
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
            if (userName.StartsWith("@"))
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
            Version = Assembly.GetExecutingAssembly().GetName().Version?.ToString() ?? "---";
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
                    var serializerOptions = new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        WriteIndented = true,
                    };
                    PagesCatalog = JsonSerializer.Deserialize<PagesCatalog>(content, serializerOptions) ?? new PagesCatalog();
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
                    var serializerOptions = new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        WriteIndented = true,
                    };
                    TemplatesCatalog = JsonSerializer.Deserialize<TemplatesCatalog>(content, serializerOptions) ?? new TemplatesCatalog();
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
                    var serializerOptions = new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        WriteIndented = true,
                    };
                    disallowList = JsonSerializer.Deserialize<List<string>>(content, serializerOptions) ?? new List<string>();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(UserNameValidation)));
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

        public event PropertyChangedEventHandler? PropertyChanged;

        public PagesCatalog PagesCatalog { get; private set; }
        
        public TemplatesCatalog TemplatesCatalog { get; private set; }
        
        private static List<string> disallowList = new();

        public string Version { get; set; }

        #region User name

        public void ClearUser()
        {
            UserName = "";
            Membership = "None";
            FirstForPage = false;
            CommunityTag = false;
            NewMembership = "None";
        }

        private string userName = "";

        public string UserName
        {
            get { return userName; }
            set
            {
                if (userName != value)
                {
                    userName = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(UserName)));
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
            get { return userNameValidation; }
            private set
            {
                if (userNameValidation != value)
                {
                    userNameValidation = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(UserNameValidation)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyScripts)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyNewMembershipScript)));
                }
            }
        }

        #endregion

        #region Membership level

        public static string[] Memberships
        {
            get
            {
                return new[]
                {
                    "None",
                    "Artist",
                    "Member",
                    "VIP Member",
                    "VIP Gold Member",
                    "Platinum Member",
                    "Elite Member",
                    "Hall of Fame Member",
                    "Diamond Member",
                };
            }
        }

        private string membership = "None";

        public string Membership
        {
            get { return membership; }
            set
            {
                if (membership != value)
                {
                    membership = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Membership)));
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
            get { return membershipValidation; }
            private set
            {
                if (membershipValidation != value)
                {
                    membershipValidation = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(MembershipValidation)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyScripts)));
                }
            }
        }

        #endregion

        #region Your name

        private string yourName = Settings.Default.YourName ?? "";

        public string YourName
        {
            get { return yourName; }
            set
            {
                if (yourName != value)
                {
                    yourName = value;
                    Settings.Default.YourName = YourName;
                    Settings.Default.Save();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(YourName)));
                    YourNameValidation = ValidateUserName(YourName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourNameValidation = ValidateUserName(Settings.Default.YourName ?? "");

        public ValidationResult YourNameValidation
        {
            get { return yourNameValidation; }
            private set
            {
                if (yourNameValidation != value)
                {
                    yourNameValidation = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(YourNameValidation)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyScripts)));
                }
            }
        }

        #endregion

        #region Your first name

        private string yourFirstName = Settings.Default.YourFirstName ?? "";

        public string YourFirstName
        {
            get { return yourFirstName; }
            set
            {
                if (yourFirstName != value)
                {
                    yourFirstName = value;
                    Settings.Default.YourFirstName = YourFirstName;
                    Settings.Default.Save();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(YourFirstName)));
                    YourFirstNameValidation = ValidateValueNotEmpty(YourFirstName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

        private ValidationResult yourFirstNameValidation = ValidateUserName(Settings.Default.YourFirstName ?? "");

        public ValidationResult YourFirstNameValidation
        {
            get { return yourFirstNameValidation; }
            private set
            {
                if (yourFirstNameValidation != value)
                {
                    yourFirstNameValidation = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(YourFirstNameValidation)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyScripts)));
                }
            }
        }

        #endregion

        #region Pages

        private string[] pages = Array.Empty<string>();

        public string[] Pages
        {
            get { return pages; }
            set
            {
                if (pages != value)
                {
                    pages = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Pages)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Page)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageNameEnabled)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageNameDisabled)));
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

        private string page = Settings.Default.Page ?? "default";

        public string Page
        {
            get { return page; }
            set
            {
                if (page != value)
                {
                    page = value;
                    Settings.Default.Page = Page;
                    Settings.Default.Save();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Page)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageNameEnabled)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageNameDisabled)));
                    PageValidation = CalculatePageValidation(Page, PageName);
                    PlaceholdersMap[Script.Feature].Clear();
                    PlaceholdersMap[Script.Comment].Clear();
                    PlaceholdersMap[Script.OriginalPost].Clear();
                    UpdateScripts();
                }
            }
        }

        private ValidationResult pageValidation = CalculatePageValidation(Settings.Default.Page ?? "default", Settings.Default.PageName);

        public ValidationResult PageValidation
        {
            get { return pageValidation; }
            private set
            {
                if (pageValidation != value)
                {
                    pageValidation = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageValidation)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyScripts)));
                }
            }
        }

        public bool PageNameDisabled
        {
            get { return !PageNameEnabled; }
        }
        public bool PageNameEnabled
        {
            get { return Page == "default"; }
        }

        private string pageName = Settings.Default.PageName;

        public string PageName
        {
            get { return pageName; }
            set
            {
                if (pageName != value)
                {
                    pageName = value;
                    Settings.Default.PageName = PageName;
                    Settings.Default.Save();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(PageName)));
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

        public static string[] StaffLevels
        {
            get
            {
                return new[]
                {
                    "Mod",
                    "Co-Admin",
                    "Admin",
                };
            }
        }

        private string staffLevel = Settings.Default.StaffLevel;

        public string StaffLevel
        {
            get { return staffLevel; }
            set
            {
                if (staffLevel != value)
                {
                    staffLevel = value;
                    Settings.Default.StaffLevel = StaffLevel;
                    Settings.Default.Save();
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(StaffLevel)));
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
            get { return firstForPage; }
            set
            {
                if (firstForPage != value)
                {
                    firstForPage = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FirstForPage)));
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Community tag

        private bool communityTag = false;

        public bool CommunityTag
        {
            get { return communityTag; }
            set
            {
                if (communityTag != value)
                {
                    communityTag = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CommunityTag)));
                    UpdateScripts();
                }
            }
        }

        #endregion

        #region Feature script

        public Dictionary<Script, string> Scripts { get; private set; }

        public string FeatureScript
        {
            get { return Scripts[Script.Feature]; }
            set
            {
                if (Scripts[Script.Feature] != value)
                {
                    Scripts[Script.Feature] = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FeatureScript)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FeatureScriptPlaceholderVisibility)));
                }
            }
        }

        public Visibility FeatureScriptPlaceholderVisibility
        {
            get { return ScriptHasPlaceholder(Script.Feature) ? Visibility.Visible : Visibility.Collapsed; }
        }

        #endregion

        #region Comment script

        public string CommentScript
        {
            get { return Scripts[Script.Comment]; }
            set
            {
                if (Scripts[Script.Comment] != value)
                {
                    Scripts[Script.Comment] = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CommentScript)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CommentScriptPlaceholderVisibility)));
                }
            }
        }

        public Visibility CommentScriptPlaceholderVisibility
        {
            get { return ScriptHasPlaceholder(Script.Comment) ? Visibility.Visible : Visibility.Collapsed; }
        }

        #endregion

        #region Original post script

        public string OriginalPostScript
        {
            get { return Scripts[Script.OriginalPost]; }
            set
            {
                if (Scripts[Script.OriginalPost] != value)
                {
                    Scripts[Script.OriginalPost] = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(OriginalPostScript)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(OriginalPostScriptPlaceholderVisibility)));
                }
            }
        }

        public Visibility OriginalPostScriptPlaceholderVisibility
        {
            get { return ScriptHasPlaceholder(Script.OriginalPost) ? Visibility.Visible : Visibility.Collapsed; }
        }

        #endregion

        #region New membership level

        public static string[] NewMemberships
        {
            get
            {
                return new[]
                {
                    "None",
                    "Member",
                    "VIP Member",
                };
            }
        }

        private string newMembership = "None";

        public string NewMembership
        {
            get { return newMembership; }
            set
            {
                if (newMembership != value)
                {
                    newMembership = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(NewMembership)));
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CanCopyNewMembershipScript)));
                    UpdateNewMembershipScripts();
                }
            }
        }

        private string newMembershipScript = "";

        public string NewMembershipScript
        {
            get { return newMembershipScript; }
            set
            {
                if (newMembershipScript != value)
                {
                    newMembershipScript = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(NewMembershipScript)));
                }
            }
        }

        #endregion

        #region Themes

        private string themeName = "";

        public string ThemeName
        {
            get
            {
                return themeName switch
                {
                    "SoftDark" => "Soft dark",
                    "LightTheme" => "Light",
                    "DeepDark" => "Deep dark",
                    "DarkGreyTheme" => "Dark gray",
                    "GreyTheme" => "Gray",
                    _ => themeName,
                };
            }
            set
            {
                if (themeName != value)
                {
                    themeName = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(ThemeName)));
                }
            }
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
                placeholders.Add(match.Captures.First().Value.Trim(new[] { '[', ']' }));
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

        public bool CanCopyScripts
        {
            get
            {
                return UserNameValidation.Valid &&
                    MembershipValidation.Valid &&
                    YourNameValidation.Valid &&
                    YourFirstNameValidation.Valid &&
                    PageValidation.Valid;
            }
        }

        public bool CanCopyNewMembershipScript
        {
            get
            {
                return NewMembership != "None" &&
                    UserNameValidation.Valid;
            }
        }

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
                var featureScriptTemplate = GetTemplate("feature", pageName, FirstForPage, CommunityTag);
                var commentScriptTemplate = GetTemplate("comment", pageName, FirstForPage, CommunityTag);
                var originalPostScriptTemplate = GetTemplate("original post", pageName, FirstForPage, CommunityTag);
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
            bool communityTag)
        {
            TemplateEntry? template = null;
            var defaultTemplatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == "default");
            var templatePage = TemplatesCatalog.Pages.FirstOrDefault(page => page.Name == pageName);
            if (communityTag)
            {
                template = templatePage?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
                template ??= defaultTemplatePage?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
            }
            else if (firstForPage)
            {
                template = templatePage?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
                template ??= defaultTemplatePage?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
            }
            template ??= templatePage?.Templates.FirstOrDefault(template => template.Name == templateName);
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

        public void CopyScript(Window owner, Script script, bool force = false, bool withPlaceholders = false)
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
                    Owner = owner
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
}
