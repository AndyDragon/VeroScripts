using System;
using System.Collections.ObjectModel;
using System.ComponentModel;
using System.Net.Http;
using System.Net.Http.Headers;
using System.Text.Json;
using System.Text.RegularExpressions;
using Vero_Scripts.Properties;

namespace Vero_Scripts
{
    public class HubsPackage
    {
        public HubsPackage() 
        {
            Hubs = Array.Empty<HubPackage>();
        }

        public HubPackage[] Hubs { get; set; }
    }

    public class HubPackage
    {
        public HubPackage()
        {
            Name = string.Empty;
            Templates = Array.Empty<TemplatePackage>();
        }

        public string Name { get; set; }
        
        public TemplatePackage[] Templates { get; set; }
    }

    public class TemplatePackage
    {
        public TemplatePackage()
        {
            Name = string.Empty;
            Template = string.Empty;
        }

        public string Name { get; set; }
        
        public string Template { get; set; }
    }

    public class Placeholder : INotifyPropertyChanged
    {
        public Placeholder(string name)
        {
            Name = name;
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        private string name = "";
        public string Name
        {
            get { return name; }
            set
            {
                if (value != name)
                {
                    name = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Name)));
                }
            }
        }

        private string value = "";
        public string Value
        {
            get { return value; }
            set
            {
                if (value != this.value)
                {
                    this.value = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(Value)));
                }
            }
        }
    }

    public partial class ScriptsViewModel : INotifyPropertyChanged
    {
        private readonly HttpClient httpClient = new();

        public ScriptsViewModel()
        {
            Hubs = new HubsPackage();
            _ = LoadHubs();
            Placeholders = new ObservableCollection<Placeholder>();
        }

        private async Task LoadHubs()
        {
            try
            {
                // Disable client-side caching.
                httpClient.DefaultRequestHeaders.CacheControl = new CacheControlHeaderValue
                {
                    NoCache = true
                };
                var hubsUri = new Uri("https://andydragon.com/depot/VERO/hubs.json");
                var content = await httpClient.GetStringAsync(hubsUri);
                if (!string.IsNullOrEmpty(content))
                {
                    var serializerOptions = new JsonSerializerOptions
                    {
                        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
                        WriteIndented = true,
                    };
                    Hubs = JsonSerializer.Deserialize<HubsPackage>(content, serializerOptions) ?? new HubsPackage();
                    Pages = Hubs.Hubs.Select(hub => hub.Name).ToArray();
                }
            }
            catch (Exception ex)
            {
                // TODO andydragon : handle errors
                Console.WriteLine("Error occurred: {0}", ex.Message);
            }
        }

        public event PropertyChangedEventHandler? PropertyChanged;

        public HubsPackage Hubs { get; private set; }

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
                    Placeholders.Clear();
                    UpdateScripts();
                    UpdateNewMembershipScripts();
                }
            }
        }

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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

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
                }
            }
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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

        public bool PageNameDisabled
        {
            get { return !PageNameEnabled; }
        }
        public bool PageNameEnabled
        {
            get { return Page == "default" || string.IsNullOrEmpty(Page); }
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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

        public static string[] StaffLevels
        {
            get
            {
                return new[]
                {
                    "Mod",
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
                    Placeholders.Clear();
                    UpdateScripts();
                }
            }
        }

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

        private string featureScript = "";

        public string FeatureScript
        {
            get { return featureScript; }
            set
            {
                if (featureScript != value)
                {
                    featureScript = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(FeatureScript)));
                }
            }
        }

        private string commentScript = "";

        public string CommentScript
        {
            get { return commentScript; }
            set
            {
                if (commentScript != value)
                {
                    commentScript = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(CommentScript)));
                }
            }
        }

        private string originalPostScript = "";

        public string OriginalPostScript
        {
            get { return originalPostScript; }
            set
            {
                if (originalPostScript != value)
                {
                    originalPostScript = value;
                    PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(nameof(OriginalPostScript)));
                }
            }
        }

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

        public ObservableCollection<Placeholder> Placeholders { get; private set; }

        public bool CheckForPlaceholders(string[] scripts, bool force = false)
        {
            var placeholders = new List<string>();
            foreach (var script in scripts)
            {
                var matches = PlaceholderRegex().Matches(script);
                foreach (Match match in matches.Cast<Match>())
                {
                    placeholders.Add(match.Captures.First().Value);
                }
            }
            if (placeholders.Count != 0)
            {
                var needEditor = false;
                foreach (var placeholderName in placeholders)
                {
                    if (Placeholders.FirstOrDefault(placeholder => placeholder.Name == placeholderName) == null)
                    {
                        needEditor = true;
                        Placeholders.Add(new Placeholder(placeholderName));
                    }
                }
                return needEditor || force;
            }
            return false;
        }

        public string ProcessPlaceholders(string script)
        {
            var result = script;
            foreach (var placeholder in Placeholders)
            {
                result = result.Replace(placeholder.Name, placeholder.Value);
            }
            return result;
        }

        private void UpdateScripts()
        {
            if (string.IsNullOrEmpty(UserName)
                || string.IsNullOrEmpty(Membership)
                || Membership == "None"
                || string.IsNullOrEmpty(YourName)
                || string.IsNullOrEmpty(YourFirstName)
                || string.IsNullOrEmpty(Page)
                || Page == "default" && string.IsNullOrEmpty(PageName))
            {
                FeatureScript = "";
                CommentScript = "";
                OriginalPostScript = "";
            }
            else
            {
                var pageName = Page == "default" || string.IsNullOrEmpty(Page) ? PageName : Page;
                var featureScriptTemplate = GetTemplate("feature", pageName, FirstForPage, CommunityTag);
                var commentScriptTemplate = GetTemplate("comment", pageName, FirstForPage, CommunityTag);
                var originalPostScriptTemplate = GetTemplate("original post", pageName, FirstForPage, CommunityTag);
                FeatureScript = featureScriptTemplate
                    .Replace("%%PAGENAME%%", pageName)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                CommentScript = commentScriptTemplate
                    .Replace("%%PAGENAME%%", pageName)
                    .Replace("%%MEMBERLEVEL%%", Membership)
                    .Replace("%%USERNAME%%", UserName)
                    .Replace("%%YOURNAME%%", YourName)
                    .Replace("%%YOURFIRSTNAME%%", YourFirstName)
                    // Special case for 'YOUR FIRST NAME' since it's now autofilled.
                    .Replace("[[YOUR FIRST NAME]]", YourFirstName)
                    .Replace("%%STAFFLEVEL%%", StaffLevel);
                OriginalPostScript = originalPostScriptTemplate
                    .Replace("%%PAGENAME%%", pageName)
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
            TemplatePackage? template = null;
            var defaultHub = Hubs.Hubs.FirstOrDefault(hub => hub.Name == "default");
            var hub = Hubs.Hubs.FirstOrDefault(hub => hub.Name == pageName);
            if (communityTag)
            {
                template = hub?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
                template ??= defaultHub?.Templates.FirstOrDefault(template => template.Name == "community " + templateName);
            } 
            else if (firstForPage)
            {
                template = hub?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
                template ??= defaultHub?.Templates.FirstOrDefault(template => template.Name == "first " + templateName);
            }
            template ??= hub?.Templates.FirstOrDefault(template => template.Name == templateName);
            template ??= defaultHub?.Templates.FirstOrDefault(template => template.Name == templateName);
            return template?.Template ?? "";
        }

        private void UpdateNewMembershipScripts()
        {
            if (NewMembership == "None" || string.IsNullOrEmpty(UserName)) 
            {
                NewMembershipScript = "";
            }
            else if (NewMembership == "Member") 
            {
                NewMembershipScript =
                    "Congratulations @" + UserName + " on your 5th feature!\n" +
                    "\n" +
                    "I took the time to check the number of features you have with the SNAP Community and wanted to share with you that you are now a Member of the SNAP Community!\n" +
                    "\n" +
                    "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
                    "\n" +
                    "Please consider adding ✨ SNAP Community Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag.\n";
        }
            else if (NewMembership == "VIP Member") 
            {
                NewMembershipScript =
                    "Congratulations @" + UserName + " on your 15th feature!\n" +
                    "\n" +
                    "I took the time to check the number of features you have with the SNAP Community and wanted to share that you are now a VIP Member of the SNAP Community!\n" +
                    "\n" +
                    "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
                    "\n" +
                    "Please consider adding ✨ SNAP VIP Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag.";
        }
        }

        [GeneratedRegex("\\[\\[([^\\]]*)\\]\\]")]
        private static partial Regex PlaceholderRegex();
    }
}
