namespace VeroScripts
{
    public class PagesCatalog
    {
        public PagesCatalog()
        {
            Pages = [];
            Hubs = new Dictionary<string, IList<HubPageEntry>>();
        }

        public PageEntry[] Pages { get; set; }

        public IDictionary<string, IList<HubPageEntry>> Hubs { get; set; }
    }

    public class PageEntry
    {
        public PageEntry()
        {
            Name = string.Empty;
        }

        public string Name { get; set; }
        public string? PageName { get; set; }
    }

    public class HubPageEntry
    {
        public HubPageEntry()
        {
            Name = string.Empty;
        }

        public string Name { get; set; }
        public string? PageName { get; set; }
        public IList<string>? Users { get; set; }
    }

    public class LoadedPage
    {
        public LoadedPage(PageEntry page)
        {
            Name = page.Name;
            PageName = page.PageName;
        }

        public LoadedPage(string hubName, HubPageEntry page)
        {
            HubName = hubName;
            Name = page.Name;
            PageName = page.PageName;
        }

        public string Id
        {
            get
            {
                if (!string.IsNullOrEmpty(HubName))
                {
                    return $"{HubName}:{Name}";
                }
                return Name;
            }
        }
        public string Name { get; private set; }
        public string? PageName { get; private set; }
        public string? HubName { get; private set; }
        public string DisplayName
        {
            get
            {
                if (!string.IsNullOrEmpty(HubName))
                {
                    return $"{HubName}_{Name}";
                }
                return Name;
            }
        }
    }

    public class TemplatesCatalog
    {
        public TemplatesCatalog()
        {
            Pages = [];
            SpecialTemplates = [];
        }

        public TemplatePageEntry[] Pages { get; set; }

        public TemplateEntry[] SpecialTemplates { get; set; }
    }

    public class TemplatePageEntry
    {
        public TemplatePageEntry()
        {
            Name = string.Empty;
            Templates = [];
        }

        public string Name { get; set; }

        public TemplateEntry[] Templates { get; set; }
    }

    public class TemplateEntry
    {
        public TemplateEntry()
        {
            Name = string.Empty;
            Template = string.Empty;
        }

        public string Name { get; set; }

        public string Template { get; set; }
    }

    internal class LoadedPageComparer : IComparer<LoadedPage>
    {
        public int Compare(LoadedPage? x, LoadedPage? y)
        {
            if (x == null && y == null)
            {
                return 0;
            }
            if (x == null)
            {
                return -1;
            }
            if (y == null)
            {
                return 1;
            }
            if (x.Id.StartsWith('_') && y.Id.StartsWith('_'))
            {
                return string.Compare(x.Id, y.Id, true);
            }
            if (x.Id.StartsWith('_'))
            {
                return 1;
            }
            if (y.Id.StartsWith('_'))
            {
                return -1;
            }
            int hubCompare = string.Compare(x.HubName ?? "snap", y.HubName ?? "snap", true);
            if (hubCompare == 0)
            {
                return string.Compare(x.Name, y.Name, true);
            }
            return hubCompare;
        }

        public static readonly LoadedPageComparer Default = new();
    }
}
