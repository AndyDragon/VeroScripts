using System.Collections.ObjectModel;
using System.Net.Http.Headers;
using System.Text.RegularExpressions;
using CommunityToolkit.Maui.Alerts;
using CommunityToolkit.Maui.Core;
using Newtonsoft.Json;
using VeroScripts.Base;
using VeroScripts.Models;
using VeroScripts.Views;

namespace VeroScripts.ViewModels;

public enum Script
{
    Feature = 1,
    Comment,
    OriginalPost,
}

public class FeatureViewModel : NotifyPropertyChanged
{
    private readonly HttpClient _httpClient = new();

    public FeatureViewModel()
    {
        Scripts = new Dictionary<Script, string>
        {
            { Script.Feature, "" },
            { Script.Comment, "" },
            { Script.OriginalPost, "" }
        };
        PlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
        {
            { Script.Feature, [] },
            { Script.Comment, [] },
            { Script.OriginalPost, [] }
        };
        LongPlaceholdersMap = new Dictionary<Script, ObservableCollection<Placeholder>>
        {
            { Script.Feature, [] },
            { Script.Comment, [] },
            { Script.OriginalPost, [] }
        };

        UserSettings.PropertyChanged += (_, e) =>
        {
            if (e.PropertyName == nameof(SettingsViewModel.IncludeSpace))
            {
                IncludeSpace = Preferences.Default.Get(nameof(IncludeSpace), false);
            }
        };

        _ = LoadPages();
    }
    
    #region Commands

    public SimpleCommand FeatureScriptCommand => new(() =>
    {
        Application.Current?.Windows[0].Page?.Navigation.PushAsync(new ScriptPage(new ScriptViewModel(this, Script.Feature)));
    }, () => CanCopyScripts);

    public SimpleCommandWithParameter CopyScriptCommand => new(parameter =>
    {
        if (parameter is Script script)
        {
            switch (script)
            {
                case Script.Feature:
                case Script.Comment:
                case Script.OriginalPost:
                    CopyScript(script, force: true);
                    break;
                default:
                    throw new ArgumentOutOfRangeException();
            }
        }
    }, _ => CanCopyScripts);
    
    public SimpleCommand CopyNewMembershipScriptCommand => new(() =>
    {
        _ = CopyTextToClipboardAsync(NewMembershipScript, "Copied the new membership script to the clipboard");
    }, () => CanCopyNewMembershipScript);


    public SimpleCommandWithParameter NextScriptCommand => new (parameter =>
    {
        if (parameter is Script script)
        {
            switch (script)
            {
                case Script.Feature:
                    Application.Current?.Windows[0].Page?.Navigation
                        .PushAsync(new ScriptPage(new ScriptViewModel(this, Script.Comment)));
                    break;

                case Script.Comment:
                    Application.Current?.Windows[0].Page?.Navigation
                        .PushAsync(new ScriptPage(new ScriptViewModel(this, Script.OriginalPost)));
                    break;

                case Script.OriginalPost:
                    Application.Current?.Windows[0].Page?.Navigation
                        .PushAsync(new NewMembershipPage(this));
                    break;
            }
        }
    });

    public SimpleCommand NextFeatureCommand => new(() =>
    {
        Application.Current?.Windows[0].Page?.Navigation.PopToRootAsync();
        UserName = "";
        Membership = "None";
        NewMembershipScript = "None";
        FirstForPage = false;
        RawTag = false;
        CommunityTag = false;
        HubTag = false;
        UpdateScripts();
        UpdateNewMembershipScripts();
    });

    #endregion

    #region User settings
    
    private bool _includeSpace = Preferences.Default.Get(nameof(IncludeSpace), false);
    public bool IncludeSpace
    {
        get => _includeSpace;
        set
        {
            if (Set(ref _includeSpace, value))
            {
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    #endregion

    #region Server access

    private async Task LoadPages()
    {
        try
        {
            // Disable client-side caching.
            _httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var pagesUri = new Uri("https://vero.andydragon.com/static/data/pages.json");
            var content = await _httpClient.GetStringAsync(pagesUri);
            if (!string.IsNullOrEmpty(content))
            {
                var loadedPages = new List<LoadedPage>();
                var pagesCatalog = JsonConvert.DeserializeObject<ScriptsCatalog>(content) ?? new ScriptsCatalog();
                if (pagesCatalog.Hubs != null)
                {
                    loadedPages.AddRange(from hubPair in pagesCatalog.Hubs
                        from hubPage in hubPair.Value
                        select new LoadedPage(hubPair.Key, hubPage));
                }

                LoadedPages.Clear();
                foreach (var loadedPage in loadedPages.OrderBy(loadedPage => loadedPage, LoadedPageComparer.Default))
                {
                    LoadedPages.Add(loadedPage);
                }

                _ = Toast.Make($"Loaded {LoadedPages.Count} pages from the server").Show();
            }
            var page = Preferences.Default.Get(nameof(Page), "");
            SelectedPage = LoadedPages.FirstOrDefault(loadedPage => loadedPage.Id == page);
            WaitingForPages = false;
            
            await LoadTemplates();
            await LoadDisallowList();
        }
        catch (Exception ex)
        {
            Console.WriteLine("IsError occurred loading page catalog (will retry): {0}", ex.Message);
            await Toast.Make($"Failed to load the page catalog: {ex.Message}", ToastDuration.Long).Show();
            Application.Current!.Quit();
        }
    }

    private async Task LoadTemplates()
    {
        try
        {
            // Disable client-side caching.
            _httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var templatesUri = new Uri("https://vero.andydragon.com/static/data/templates.json");
            var content = await _httpClient.GetStringAsync(templatesUri);
            if (!string.IsNullOrEmpty(content))
            {
                TemplatesCatalog = JsonConvert.DeserializeObject<TemplatesCatalog>(content) ?? new TemplatesCatalog();
            }
        }
        catch (Exception ex)
        {
            Console.WriteLine("IsError occurred loading the template catalog (will retry): {0}", ex.Message);
            await Toast.Make($"Failed to load the page templates: {ex.Message}", ToastDuration.Long).Show();
            Application.Current!.Quit();
        }
    }

    private async Task LoadDisallowList()
    {
        try
        {
            // Disable client-side caching.
            _httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
            {
                NoCache = true
            };
            var disallowListsUri = new Uri("https://vero.andydragon.com/static/data/disallowlists.json");
            var disallowListsContent = await _httpClient.GetStringAsync(disallowListsUri);
            if (!string.IsNullOrEmpty(disallowListsContent))
            {
                Validation.DisallowLists =
                    JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(disallowListsContent) ?? [];
            }
            var cautionListsUri = new Uri("https://vero.andydragon.com/static/data/cautionlists.json");
            var cautionListsContent = await _httpClient.GetStringAsync(cautionListsUri);
            if (!string.IsNullOrEmpty(cautionListsContent))
            {
                Validation.CautionLists =
                    JsonConvert.DeserializeObject<Dictionary<string, List<string>>>(cautionListsContent) ?? [];
            }
        }
        catch (Exception ex)
        {
            // Do nothing, not vital
            Console.WriteLine("IsError occurred loading the disallow or caution lists (ignoring): {0}", ex.Message);
        }
    }

    #endregion

    #region Waiting state

    private bool _waitingForPages = true;

    private bool WaitingForPages
    {
        get => _waitingForPages;
        set => Set(ref _waitingForPages, value, [nameof(CanChangePage), nameof(CanChangeStaffLevel)]);
    }

    #endregion

    #region Pages

    public ObservableCollection<LoadedPage> LoadedPages { get; } = [];
    private TemplatesCatalog TemplatesCatalog { get; set; } = new();

    private LoadedPage? _selectedPage;

    public LoadedPage? SelectedPage
    {
        get => _selectedPage;
        set
        {
            if (Set(ref _selectedPage, value))
            {
                Page = SelectedPage?.Id ?? string.Empty;
                OnPropertyChanged(nameof(Memberships));
                OnPropertyChanged(nameof(ClickHubVisibility));
                OnPropertyChanged(nameof(SnapHubVisibility));
                OnPropertyChanged(nameof(SnapOrClickHubVisibility));
                OnPropertyChanged(nameof(HasSelectedPage));
                OnPropertyChanged(nameof(NoSelectedPage));
                StaffLevel = SelectedPage != null
                    ? Preferences.Default.Get(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevels[0])
                    : Preferences.Default.Get(nameof(StaffLevel), StaffLevels[0]);
                if (!StaffLevels.Contains(StaffLevel))
                {
                    StaffLevel = StaffLevels[0];
                }
                UserNameValidation = Validation.ValidateUser(SelectedPage!.HubName, UserName);
            }
        }
    }

    public bool CanChangePage => !WaitingForPages;

    public bool ClickHubVisibility => SelectedPage?.HubName == "click";

    public bool SnapHubVisibility => SelectedPage?.HubName == "snap";

    public bool SnapOrClickHubVisibility => SelectedPage?.HubName == "snap" || SelectedPage?.HubName == "click";

    public bool HasSelectedPage => SelectedPage != null;
    public bool NoSelectedPage => SelectedPage == null;

    private static ValidationResult CalculatePageValidation(string page)
    {
        return Validation.ValidateValueNotEmpty(page);
    }

    private string _page = Preferences.Default.Get(nameof(Page), "");

    public string Page
    {
        get => _page;
        set
        {
            if (Set(ref _page, value, [nameof(StaffLevels)]))
            {
                Preferences.Default.Set(nameof(Page), Page);
                PageValidation = CalculatePageValidation(Page);
            }
        }
    }

    private ValidationResult _pageValidation = CalculatePageValidation(Preferences.Default.Get(nameof(Page), ""));

    public ValidationResult PageValidation
    {
        get => _pageValidation;
        private set => Set(ref _pageValidation, value);
    }

    #endregion

    #region Staff level

    private static string[] SnapStaffLevels =>
    [
        "Mod",
        "Co-Admin",
        "Admin",
        "Guest moderator"
    ];

    private static string[] ClickStaffLevels =>
    [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    private static string[] OtherStaffLevels =>
    [
        "Mod",
        "Co-Admin",
        "Admin",
    ];

    public string[] StaffLevels =>
        SelectedPage?.HubName == "click" ? ClickStaffLevels :
        SelectedPage?.HubName == "snap" ? SnapStaffLevels :
        OtherStaffLevels;

    private string _staffLevel = Preferences.Default.Get(nameof(StaffLevel), "Mod");

    public string StaffLevel
    {
        get => _staffLevel;
        set
        {
            if (Set(ref _staffLevel, value))
            {
                if (SelectedPage != null)
                {
                    Preferences.Default.Set(nameof(StaffLevel) + ":" + SelectedPage.Id, StaffLevel);
                }
                else
                {
                    Preferences.Default.Set(nameof(StaffLevel), StaffLevel);
                }
            }
        }
    }

    public bool CanChangeStaffLevel => !WaitingForPages;

    #endregion

    #region Your alias

    private string _yourAlias = Preferences.Default.Get(nameof(YourAlias), "");

    public string YourAlias
    {
        get => _yourAlias;
        set
        {
            if (Set(ref _yourAlias, value, [nameof(YourAliasValidation)]))
            {
                Preferences.Default.Set(nameof(YourAlias), YourAlias);
                ClearAllPlaceholders();
            }
        }
    }

    public ValidationResult YourAliasValidation => Validation.ValidateUserName(YourAlias);

    #endregion

    #region Your first name

    private string _yourFirstName = Preferences.Default.Get(nameof(YourFirstName), "");

    public string YourFirstName
    {
        get => _yourFirstName;
        set
        {
            if (Set(ref _yourFirstName, value, [nameof(YourFirstNameValidation)]))
            {
                Preferences.Default.Set(nameof(YourFirstName), YourFirstName);
                ClearAllPlaceholders();
            }
        }
    }

    public ValidationResult YourFirstNameValidation => Validation.ValidateValueNotEmpty(YourFirstName);

    #endregion

    #region User name

    private string _userName = "";

    public string UserName
    {
        get => _userName;
        set
        {
            if (Set(ref _userName, value))
            {
                UserNameValidation = Validation.ValidateUser(SelectedPage!.HubName, UserName);
                ClearAllPlaceholders();
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    private ValidationResult _userNameValidation = Validation.ValidateUser("", "");

    public ValidationResult UserNameValidation
    {
        get => _userNameValidation;
        private set
        {
            if (Set(ref _userNameValidation, value))
            {
                OnPropertyChanged(nameof(CanCopyScripts));
                OnPropertyChanged(nameof(FeatureScriptCommand));
                OnPropertyChanged(nameof(CanCopyNewMembershipScript));
            }
        }
    }

    #endregion

    #region Membership levels

    private static string[] SnapMemberships =>
    [
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

    private static string[] ClickMemberships =>
    [
        "None",
        "Artist",
        "Click Member",
        "Click Bronze Member",
        "Click Silver Member",
        "Click Gold Member",
        "Click Platinum Member",
    ];

    private static string[] OtherMemberships =>
    [
        "None",
        "Artist",
    ];

    public string[] Memberships =>
        SelectedPage?.HubName switch
        {
            "click" => ClickMemberships,
            "snap" => SnapMemberships,
            _ => OtherMemberships
        };

    private string _membership = "None";

    public string Membership
    {
        get => _membership;
        set
        {
            if (Set(ref _membership, value))
            {
                MembershipValidation = Validation.ValidateValueNotDefault(Membership, "None");
                ClearAllPlaceholders();
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    private ValidationResult _membershipValidation = Validation.ValidateValueNotDefault("None", "None");

    public ValidationResult MembershipValidation
    {
        get => _membershipValidation;
        private set
        {
            if (Set(ref _membershipValidation, value))
            {
                OnPropertyChanged(nameof(CanCopyScripts));
                OnPropertyChanged(nameof(FeatureScriptCommand));
            }
        }
    }

    #endregion

    #region First for page

    private bool _firstForPage;

    public bool FirstForPage
    {
        get => _firstForPage;
        set
        {
            if (Set(ref _firstForPage, value))
            {
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    #endregion

    #region RAW tag

    private bool _rawTag;

    public bool RawTag
    {
        get => _rawTag;
        set
        {
            if (Set(ref _rawTag, value))
            {
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    #endregion

    #region Community tag

    private bool _communityTag;

    public bool CommunityTag
    {
        get => _communityTag;
        set
        {
            if (Set(ref _communityTag, value))
            {
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    #endregion

    #region Hub tag

    private bool _hubTag;

    public bool HubTag
    {
        get => _hubTag;
        set
        {
            if (Set(ref _hubTag, value))
            {
                UpdateScripts();
                UpdateNewMembershipScripts();
            }
        }
    }

    #endregion

    #region Clipboard support

    private static async Task CopyTextToClipboardAsync(string text, string successMessage)
    {
        await TrySetClipboardText(text);
        await Toast.Make(successMessage).Show();
    }

    private static async Task TrySetClipboardText(string text)
    {
        await Clipboard.SetTextAsync(text);
    }

    #endregion

    #region Feature script

    private Dictionary<Script, string> Scripts { get; set; }

    public string FeatureScript
    {
        get => Scripts[Script.Feature];
        set
        {
            if (Scripts[Script.Feature] != value)
            {
                Scripts[Script.Feature] = value;
                OnPropertyChanged();
                OnPropertyChanged(nameof(FeatureScriptLength));
                OnPropertyChanged(nameof(FeatureScriptPlaceholderVisibility));
            }
        }
    }
    
    public int FeatureScriptLength => Scripts[Script.Feature].Length;

    public Visibility FeatureScriptPlaceholderVisibility =>
        ScriptHasPlaceholder(Script.Feature) ? Visibility.Visible : Visibility.Collapsed;

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
                OnPropertyChanged();
                OnPropertyChanged(nameof(CommentScriptLength));
                OnPropertyChanged(nameof(CommentScriptPlaceholderVisibility));
            }
        }
    }
    
    public int CommentScriptLength => Scripts[Script.Comment].Length;

    public Visibility CommentScriptPlaceholderVisibility =>
        ScriptHasPlaceholder(Script.Comment) ? Visibility.Visible : Visibility.Collapsed;

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
                OnPropertyChanged();
                OnPropertyChanged(nameof(OriginalPostScriptLength));
                OnPropertyChanged(nameof(OriginalPostScriptPlaceholderVisibility));
            }
        }
    }
    
    public int OriginalPostScriptLength => Scripts[Script.OriginalPost].Length;

    public Visibility OriginalPostScriptPlaceholderVisibility =>
        ScriptHasPlaceholder(Script.OriginalPost) ? Visibility.Visible : Visibility.Collapsed;

    #endregion

    #region New membership level

    private static string[] SnapNewMemberships =>
    [
        "None",
        "Member (feature comment)",
        "Member (original post comment)",
        "VIP Member (feature comment)",
        "VIP Member (original post comment)",
    ];

    private static string[] ClickNewMemberships =>
    [
        "None",
        "Member",
        "Bronze Member",
        "Silver Member",
        "Gold Member",
        "Platinum Member",
    ];

    private static string[] OtherNewMemberships =>
    [
        "None",
    ];

    public string[] HubNewMemberships =>
        SelectedPage?.HubName == "click" ? ClickNewMemberships :
        SelectedPage?.HubName == "snap" ? SnapNewMemberships :
        OtherNewMemberships;

    private string _newMembership = "None";
    public string NewMembership
    {
        get => _newMembership;
        set
        {
            if (Set(ref _newMembership, value))
            {
                OnPropertyChanged(nameof(CanCopyNewMembershipScript));
                UpdateNewMembershipScripts();
            }
        }
    }

    private string _newMembershipScript = "";
    public string NewMembershipScript
    {
        get => _newMembershipScript;
        set => Set(ref _newMembershipScript, value);
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

    private bool ScriptHasPlaceholder(Script script)
    {
        return PlaceholderRegex.Matches(Scripts[script]).Count != 0 || LongPlaceholderRegex.Matches(Scripts[script]).Count != 0;
    }

    private bool CheckForPlaceholders(Script script, bool force = false)
    {
        var needEditor = false;

        var matches = PlaceholderRegex.Matches(Scripts[script]);
        var placeholders = matches.Select(match => match.Captures.First().Value.Trim('[', ']')).ToList();

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
                            var otherPlaceholder = PlaceholdersMap[otherScript]
                                .FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholderName);
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

        var longMatches = LongPlaceholderRegex.Matches(Scripts[script]);
        var longPlaceholders = longMatches.Select(match => match.Captures.First().Value.Trim('[', '{', '}', ']')).ToList();

        if (longPlaceholders.Count != 0)
        {
            foreach (var longPlaceholderName in longPlaceholders)
            {
                if (LongPlaceholdersMap[script]
                        .FirstOrDefault(longPlaceholder => longPlaceholder.Name == longPlaceholderName) == null)
                {
                    var longPlaceholderValue = "";
                    foreach (var otherScript in Enum.GetValues<Script>())
                    {
                        if (otherScript != script)
                        {
                            var otherLongPlaceholder = LongPlaceholdersMap[otherScript]
                                .FirstOrDefault(
                                    otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholderName);
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

    private void TransferPlaceholders(Script script)
    {
        foreach (var placeholder in PlaceholdersMap[script])
        {
            if (!string.IsNullOrEmpty(placeholder.Value))
            {
                foreach (Script otherScript in Enum.GetValues(typeof(Script)))
                {
                    if (otherScript != script)
                    {
                        var otherPlaceholder = PlaceholdersMap[otherScript]
                            .FirstOrDefault(otherPlaceholder => otherPlaceholder.Name == placeholder.Name);
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
                        var otherLongPlaceholder = LongPlaceholdersMap[otherScript]
                            .FirstOrDefault(otherLongPlaceholder => otherLongPlaceholder.Name == longPlaceholder.Name);
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
        result = PlaceholdersMap[script].Aggregate(result, (current, placeholder) => current.Replace("[[" + placeholder.Name + "]]", placeholder.Value.Trim()));
        return LongPlaceholdersMap[script].Aggregate(result, (current, longPlaceholder) => current.Replace("[{" + longPlaceholder.Name + "}]", longPlaceholder.Value.Trim()));
    }

    #endregion

    #region Script management

    public bool CanCopyScripts =>
        !UserNameValidation.IsError &&
        !MembershipValidation.IsError &&
        !YourAliasValidation.IsError &&
        !YourFirstNameValidation.IsError &&
        !PageValidation.IsError;

    public bool CanCopyNewMembershipScript =>
        NewMembership != "None" &&
        !UserNameValidation.IsError;

    private void UpdateScripts()
    {
        var pageName = Page;
        var pageId = pageName;
        var scriptPageName = pageName;
        var scriptPageHash = pageName;
        var scriptPageTitle = pageName;
        var oldHubName = _selectedPage?.HubName;
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
            MembershipValidation = Validation.ValidateValueNotDefault(Membership, "None");
        }

        if (!CanCopyScripts)
        {
            var validationErrors = "";

            void CheckValidation(string prefix, ValidationResult result)
            {
                if (!result.IsValid)
                {
                    validationErrors += prefix + ": " + (result.Message ?? "unknown") + "\n";
                }
            }

            CheckValidation("User", UserNameValidation);
            CheckValidation("Level", MembershipValidation);
            CheckValidation("You", YourAliasValidation);
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
            FeatureScript = featureScriptTemplate
                .Replace("%%PAGENAME%%", scriptPageName)
                .Replace("%%FULLPAGENAME%%", pageName)
                .Replace("%%PAGETITLE%%", scriptPageTitle)
                .Replace("%%PAGEHASH%%", scriptPageHash)
                .Replace("%%MEMBERLEVEL%%", Membership)
                .Replace("%%USERNAME%%", UserName)
                .Replace("%%YOURNAME%%", YourAlias)
                .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                .Replace("%%STAFFLEVEL%%", StaffLevel)
                .InsertSpacesInUserTags(IncludeSpace);
            CommentScript = commentScriptTemplate
                .Replace("%%PAGENAME%%", scriptPageName)
                .Replace("%%FULLPAGENAME%%", pageName)
                .Replace("%%PAGETITLE%%", scriptPageTitle)
                .Replace("%%PAGEHASH%%", scriptPageHash)
                .Replace("%%MEMBERLEVEL%%", Membership)
                .Replace("%%USERNAME%%", UserName)
                .Replace("%%YOURNAME%%", YourAlias)
                .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                .Replace("%%STAFFLEVEL%%", StaffLevel)
                .InsertSpacesInUserTags(IncludeSpace);
            OriginalPostScript = originalPostScriptTemplate
                .Replace("%%PAGENAME%%", scriptPageName)
                .Replace("%%FULLPAGENAME%%", pageName)
                .Replace("%%PAGETITLE%%", scriptPageTitle)
                .Replace("%%PAGEHASH%%", scriptPageHash)
                .Replace("%%MEMBERLEVEL%%", Membership)
                .Replace("%%USERNAME%%", UserName)
                .Replace("%%YOURNAME%%", YourAlias)
                .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                .Replace("%%STAFFLEVEL%%", StaffLevel)
                .InsertSpacesInUserTags(IncludeSpace);
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
        if (_selectedPage?.HubName == "snap" && firstForPage && rawTag && communityTag)
        {
            template = templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first raw community " + templateName);
        }

        // Next check first feature and raw
        if (_selectedPage?.HubName == "snap" && firstForPage && rawTag)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first raw " + templateName);
        }

        // Next check first feature and community
        if (_selectedPage?.HubName == "snap" && firstForPage && communityTag)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first community " + templateName);
        }

        // Next check first feature
        if (firstForPage)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "first " + templateName);
        }

        // Next check raw and community
        if (_selectedPage?.HubName == "snap" && rawTag && communityTag)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "raw community " + templateName);
        }

        // Next check raw
        if (_selectedPage?.HubName == "snap" && rawTag)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "raw " + templateName);
        }

        // Next check community
        if (_selectedPage?.HubName == "snap" && communityTag)
        {
            template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == "community " + templateName);
        }

        // Last check standard
        template ??= templatePage?.Templates.FirstOrDefault(templateEntry => templateEntry.Name == templateName);

        return template?.Template ?? "";
    }

    private string GetNewMembershipScriptName(string hubName, string newMembershipLevel)
    {
        return hubName switch
        {
            "snap" => newMembershipLevel switch
            {
                "Member (feature comment)" => "snap:member feature",
                "Member (original post comment)" => "snap:member original post",
                "VIP Member (feature comment)" => "snap:vip member feature",
                "VIP Member (original post comment)" => "snap:vip member original post",
                _ => "",
            },
            "click" => hubName + ":" + NewMembership.Replace(" ", "_").ToLowerInvariant(),
            _ => ""
        };
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
                    validationErrors += prefix + ": " + (result.Message ?? "unknown") + "\n";
                }
            }

            if (_newMembership != "None")
            {
                CheckValidation("User", UserNameValidation);
            }

            NewMembershipScript = validationErrors;
        }
        else
        {
            var hubName = SelectedPage?.HubName;
            var pageName = Page;
            var scriptPageName = pageName;
            var scriptPageHash = pageName;
            var scriptPageTitle = pageName;
            var sourcePage = LoadedPages.FirstOrDefault(page => page.Id == Page);
            if (sourcePage != null)
            {
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
                var template =
                    TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == templateName);
                NewMembershipScript = (template?.Template ?? "")
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourAlias)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel)
                    .InsertSpacesInUserTags(IncludeSpace);
            }
            else if (NewMembership == "Member")
            {
                var template =
                    TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new member");
                NewMembershipScript = (template?.Template ?? "")
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourAlias)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel)
                    .InsertSpacesInUserTags(IncludeSpace);
            }
            else if (NewMembership == "VIP Member")
            {
                var template =
                    TemplatesCatalog.SpecialTemplates.FirstOrDefault(template => template.Name == "new vip member");
                NewMembershipScript = (template?.Template ?? "")
                    .Replace("%%PAGENAME%%", scriptPageName)
                    .Replace("%%FULLPAGENAME%%", pageName)
                    .Replace("%%PAGETITLE%%", scriptPageTitle)
                    .Replace("%%PAGEHASH%%", scriptPageHash)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourAlias)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel)
                    .InsertSpacesInUserTags(IncludeSpace);
            }
        }
    }

    private readonly Dictionary<Script, string> _scriptNames = new()
    {
        { Script.Feature, "feature" },
        { Script.Comment, "comment" },
        { Script.OriginalPost, "original post" },
    };

    private void CopyScript(Script script, bool force = false, bool withPlaceholders = false)
    {
        if (withPlaceholders)
        {
            var unprocessedScript = Scripts[script];
            _ = CopyTextToClipboardAsync(unprocessedScript, "Copied the " + _scriptNames[script] + " script with placeholders to the clipboard");
        }
        else if (CheckForPlaceholders(script, force))
        {
            var editor = new PlaceholderEditor(this, script);
            Application.Current?.Windows[0].Page?.Navigation.PushAsync(editor);
        }
        else
        {
            var processedScript = ProcessPlaceholders(script);
            TransferPlaceholders(script);
            _ = CopyTextToClipboardAsync(processedScript, "Copied the " + _scriptNames[script] + " script to the clipboard");
        }
    }
    
    public void CopyScriptFromPlaceholders(Script script, bool withPlaceholders = false)
    {
        if (withPlaceholders)
        {
            _ = CopyTextToClipboardAsync(Scripts[script], "Copied the " + _scriptNames[script] + " script with placeholders to the clipboard");
        }
        else
        {
            TransferPlaceholders(script);
            _ = CopyTextToClipboardAsync(ProcessPlaceholders(script), "Copied the " + _scriptNames[script] + " script to the clipboard");
        }
    }

    #endregion
    
    #region Script

    public string GetScriptTitle(Script script)
    {
        return script switch
        {
            Script.Feature => "Feature",
            Script.Comment => "Comment",
            Script.OriginalPost => "Original post",
            _ => ""
        };
    }

    public string GetScriptText(Script script)
    {
        return Scripts[script];
    }
    
    public bool SetScriptText(Script script, string scriptText)
    {
        if (scriptText != Scripts[script])
        {
            Scripts[script] = scriptText;
            return true;
        }

        return false;
    }
    
    public int GetScriptLength(Script script)
    {
        return Scripts[script].Length;
    }

    public bool GetScriptHasPlaceholders(Script script)
    {
        return ScriptHasPlaceholder(script);
    }

    #endregion

    private static readonly Regex PlaceholderRegex = new(@"\[\[([^\]]*)\]\]");
    private static readonly Regex LongPlaceholderRegex = new(@"\[\{([^\}]*)\}\]");
}

public static class StringExtensions
{
    public static string InsertSpacesInUserTags(this string input, bool doReplacements = false)
    {
        return !doReplacements ? input : Regex.Replace(input, @"(^|\s|\()@([\w]+)(\s|$|,|\.|\:|\))", "$1@ $2$3");
    }
}
