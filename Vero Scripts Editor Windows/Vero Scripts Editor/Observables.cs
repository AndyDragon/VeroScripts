using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Diagnostics;

namespace VeroScriptsEditor
{
    public class ObservableCatalog: NotifyPropertyChanged
    {
        public ObservableCatalog(PagesCatalog pages, TemplatesCatalog templates)
        {
            // Add and connect the template pages.
            foreach (var templatePage in templates.Pages)
            {
                var observableTemplatePage = new ObservableTemplatePage(templatePage);
                TemplatePages.Add(observableTemplatePage);
                observableTemplatePage.PropertyChanged += OnChildPropertyChanged;
            }
            TemplatePages.CollectionChanged += (object? sender, NotifyCollectionChangedEventArgs e) =>
            {
                // TODO andydragon : what about connecting and disconnecting items...
                OnPropertyChanged(nameof(IsDirty));
            };

            // Add and connect the pages.
            var observablePages = new List<ObservablePage>();
            foreach(var hub in pages.Hubs.Keys)
            {
                foreach (var page in pages.Hubs[hub])
                {
                    var observablePage = new ObservablePage(hub, page, TemplatePages);
                    observablePages.Add(observablePage);
                    observablePage.PropertyChanged += OnChildPropertyChanged;
                }
            }
            foreach (var page in observablePages.OrderBy(page => page, ObservablePageComparer.Default))
            {
                Pages.Add(page);
            }
            Pages.CollectionChanged += (object? sender, NotifyCollectionChangedEventArgs e) =>
            {
                // TODO andydragon : what about connecting and disconnecting items...
                OnPropertyChanged(nameof(IsDirty));
            };
        }

        private void OnChildPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(IsDirty))
            {
                OnPropertyChanged(nameof(IsDirty));
            }
        }

        public ObservableCollection<ObservablePage> Pages { get; } = [];

        public ObservableCollection<ObservableTemplatePage> TemplatePages { get; } = [];

        public bool IsDirty
        {
            get => Pages.Any(page => page.IsDirty) || TemplatePages.Any(page => page.IsDirty);
        }
    }

    public class ObservablePage : NotifyPropertyChanged
    {
        public ObservablePage(string hubName, PageEntry page, ObservableCollection<ObservableTemplatePage> templatePages)
        {
            HubName = hubName;
            Name = page.Name;
            PageName = page.PageName;
            Title = page.Title;
            HashTag = page.HashTag;
            templatePage = templatePages.FirstOrDefault(templatePage => templatePage.Name == Id);
            if (templatePage != null)
            {
                templatePage.PropertyChanged += (object? sender, PropertyChangedEventArgs e) =>
                {
                    if (e.PropertyName == nameof(IsDirty))
                    {
                        OnPropertyChanged(nameof(IsDirty));
                    }
                };
            }
        }

        private readonly ObservableTemplatePage? templatePage;

        public string Id { get => $"{HubName}:{Name}"; }
        public string HubName { get; private set; }
        public string Name { get; private set; }
        public string? PageName { get; private set; }
        public string? Title { get; private set; }
        public string? HashTag { get; private set; }
        public string DisplayName { get => (string.IsNullOrEmpty(HubName) || HubName == "other") ? Name : $"{HubName}_{Name}"; }

        private bool isDirty = false;
        public bool IsDirty
        {
            get => isDirty || (templatePage?.IsDirty ?? false);
            set => Set(ref isDirty, value);
        }
    }

    public class ObservableTemplatePage : NotifyPropertyChanged
    {
        public ObservableTemplatePage(TemplatePageEntry page)
        {
            this.name = page.Name;
            foreach (var template in page.Templates)
            {
                var observableTemplate = new ObservableTemplate(template);
                Templates.Add(observableTemplate);
                observableTemplate.PropertyChanged += OnChildPropertyChanged;
            }
            Templates.CollectionChanged += (object? sender, NotifyCollectionChangedEventArgs e) =>
            {
                // TODO andydragon : what about connecting and disconnecting items...
                OnPropertyChanged(nameof(IsDirty));
            };
        }

        private void OnChildPropertyChanged(object? sender, PropertyChangedEventArgs e)
        {
            if (e.PropertyName == nameof(IsDirty))
            {
                OnPropertyChanged(nameof(IsDirty));
            }
        }

        public ObservableTemplate AddTemplate(string newTemplate)
        {
            var observableTemplate = new ObservableTemplate(new TemplateEntry { Name = newTemplate, Template = "- script -" })
            {
                IsNew = true
            };
            Templates.Add(observableTemplate);
            observableTemplate.PropertyChanged += OnChildPropertyChanged;
            return observableTemplate;
        }

        private string name;
        public string Name
        {
            get => name;
            set => Set(ref name, value);
        }

        public ObservableCollection<ObservableTemplate> Templates { get; } = [];

        public bool IsDirty
        {
            get => Templates.Any(template => template.IsDirty || template.IsNew);
        }
    }

    public class ObservableTemplate(TemplateEntry template) : NotifyPropertyChanged
    {
        private string name = template.Name;
        public string Name
        {
            get => name;
            set => Set(ref name, value);
        }

        private string template = template.Template;
        public string Template
        {
            get => template;
            set => Set(ref template, value, [nameof(IsDirty)]);
        }

        private string originalTemplate = template.Template;
        public string OriginalTemplate
        {
            get => originalTemplate;
            set => Set(ref originalTemplate, value, [nameof(IsDirty)]);
        }

        private bool isNew = false;
        public bool IsNew
        {
            get => isNew;
            set => Set(ref isNew, value, [nameof(IsDirty)]);
        }

        public bool IsDirty
        {
            get => Template != OriginalTemplate;
        }
    }
}
