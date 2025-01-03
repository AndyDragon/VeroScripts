using Newtonsoft.Json;

namespace VeroScriptsEditor
{
    public class PagesCatalog
    {
        public PagesCatalog()
        {
            Hubs = new Dictionary<string, IList<PageEntry>>();
        }

        public IDictionary<string, IList<PageEntry>> Hubs { get; set; }
    }

    public class PageEntry
    {
        public PageEntry()
        {
            Name = string.Empty;
        }

        public string Name { get; set; }
        public string? PageName { get; set; }
        public string? Title { get; set; }
        public string? HashTag { get; set; }
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

    internal class ObservablePageComparer : IComparer<ObservablePage>
    {
        public int Compare(ObservablePage? x, ObservablePage? y)
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
            if (x.HubName == "other" && y.HubName == "other")
            {
                return string.Compare(x.Id, y.Id, true);
            }
            if (x.HubName == "other")
            {
                return 1;
            }
            if (y.HubName == "other")
            {
                return -1;
            }
            return string.Compare(x.DisplayName, y.DisplayName, true);
        }

        public static readonly ObservablePageComparer Default = new();
    }
}
