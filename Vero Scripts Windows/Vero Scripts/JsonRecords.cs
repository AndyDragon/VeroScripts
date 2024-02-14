using System;

namespace Vero_Scripts
{
    public class PagesCatalog
    {
        public PagesCatalog()
        {
            Pages = Array.Empty<PageEntry>();
        }

        public PageEntry[] Pages { get; set; }
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

    public class TemplatesCatalog
    {
        public TemplatesCatalog()
        {
            Pages = Array.Empty<TemplatePageEntry>();
            SpecialTemplates = Array.Empty<TemplateEntry>();
        }

        public TemplatePageEntry[] Pages { get; set; }

        public TemplateEntry[] SpecialTemplates { get; set; }
    }

    public class TemplatePageEntry
    {
        public TemplatePageEntry()
        {
            Name = string.Empty;
            Templates = Array.Empty<TemplateEntry>();
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
}
