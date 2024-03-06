using System.Text.RegularExpressions;
using Newtonsoft.Json;

namespace PrepareTemplates;

class Program
{
    static readonly Regex hubUnderscoreReplacementRegEx = new(Regex.Escape("_"));

    static void Main()
    {
        var originalForeground = Console.ForegroundColor;
        var cwd = Directory.GetCurrentDirectory();
        var pageCatalog = new PageCatalog();
        var templateCatalog = new TemplateCatalog();
        var warnings = new List<string>();
        var templateFolders = new Dictionary<string, IDictionary<string, string>>();
        EnumerateFolder(cwd, ref templateFolders, ref warnings);
        foreach (var folder in templateFolders.Keys)
        {
            var pageName = folder.Split(Path.DirectorySeparatorChar).Last();
            var templates = templateFolders[folder];
            if (templates.Count != 0)
            {
                // TODO : eventually remove the new membership scripts at the root
                //        once the new version is around for a month or so.
                if (folder.Contains("/$/") || folder.EndsWith("/$"))
                {
                    var hubName = string.Empty;
                    if (!folder.EndsWith("/$"))
                    {
                        hubName = pageName;
                    }
                    // Add special templates to template catalog.
                    foreach (var key in templates.Keys)
                    {
                        var templateKey = string.IsNullOrEmpty(hubName) ? key : (hubName + ":" + key);
                        templateCatalog.SpecialTemplates.Add(new Template(templateKey, templates[key]));
                    }
                }
                else
                {
                    // Add page to all the catalogs.
                    var templatePageName = pageName;
                    if (File.Exists(Path.Combine(folder, "manifest.json")))
                    {
                        var manifestFile = File.ReadAllText(Path.Combine(folder, "manifest.json"));
                        var manifest = JsonConvert.DeserializeObject<Manifest>(manifestFile);
                        var pageHub = manifest?.Hub;
                        if (!string.IsNullOrEmpty(pageHub))
                        {
                            if (string.IsNullOrEmpty(manifest?.Page))
                            {
                                warnings.Add(string.Format("PREP0102: The page '{0}' has a manifest but the manifest is missing the Page", pageName));
                            }
                            var hubPage = new Page(manifest?.Page ?? pageName)
                            {
                                PageName = manifest?.PageName,
                            };
                            if (!pageCatalog.Hubs.TryGetValue(pageHub, out IList<Page>? value))
                            {
                                value = new List<Page>();
                                pageCatalog.Hubs[pageHub] = value;
                            }

                            value.Add(hubPage);
                            if (!string.Equals(pageName, string.Format("{0}_{1}", manifest?.Hub, manifest?.Page)))
                            {
                                warnings.Add(string.Format("PREP0101: The hub '{0}' page '{1}' has location '{2}' that was not expected", manifest?.Hub, manifest?.Page, pageName));
                            }

                            // Fix the template name for hubs.
                            templatePageName = hubUnderscoreReplacementRegEx.Replace(templatePageName, ":", 1);
                        }
                        else
                        {
                            if (pageName == "default")
                            {
                                var page = new Page(pageName)
                                {
                                    PageName = manifest?.PageName
                                };
                                pageCatalog.Pages.Add(page);
                            }
                            else
                            {
                                warnings.Add(string.Format("PREP0103: The page '{0}' has a manifest or the manifest is missing the Hub", pageName));
                            }
                        }
                    }
                    else
                    {
                        warnings.Add(string.Format("PREP0103: The page '{0}' is missing the manifest", pageName));
                    }
                    templateCatalog.Pages.Add(new TemplatePage(templatePageName, templates));
                }
            }
        }

        using var pageCatalogFile = File.CreateText(Path.Combine(cwd, "pages.json"));
        var pageCatalogJson = JsonConvert.SerializeObject(pageCatalog/*, Formatting.Indented*/); // minimize
        pageCatalogFile.WriteLine(pageCatalogJson);
        using var templateCatalogFile = File.CreateText(Path.Combine(cwd, "templates.json"));
        var templateCatalogJson = JsonConvert.SerializeObject(templateCatalog, Formatting.Indented);
        templateCatalogFile.WriteLine(templateCatalogJson);

        if (warnings.Count != 0)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            foreach (var warning in warnings)
            {
                Console.WriteLine("{0}", warning);
            }
        }
        else
        {
            Console.ForegroundColor = ConsoleColor.Green;
            Console.WriteLine("No warnings found");
        }
        Console.ForegroundColor = originalForeground;
    }

    private static void EnumerateFolder(
        string currentFolder,
        ref Dictionary<string, IDictionary<string, string>> templateFolders,
        ref List<string> warnings)
    {
        var folderName = currentFolder.Split(Path.DirectorySeparatorChar).Last();
        foreach (var folder in Directory.EnumerateDirectories(currentFolder)
                                        .OrderBy(dir => dir, PageDirectoryComparer.Default))
        {
            var pageName = folder.Split(Path.DirectorySeparatorChar).Last();
            templateFolders.Add(folder, new Dictionary<string, string>());
            Console.WriteLine("Searching {0} folder...", folder);
            foreach (var file in Directory.EnumerateFiles(folder, "*.template")
                                          .Order())
            {
                var fileName = Path.GetFileNameWithoutExtension(file);

                if (!string.Equals(folderName, "$") && !string.Equals(pageName, "$"))
                {
                    ValidateFileName(pageName, fileName, ref warnings);
                }
                Console.WriteLine("\tAdding {0}...", file);
                var template = File.ReadAllText(file);
                templateFolders[folder].Add(fileName, template);
                ValidateTemplate(pageName, fileName, template, ref warnings);
            }
            EnumerateFolder(folder, ref templateFolders, ref warnings);
        }
    }

    private static readonly string[] validFileNames = new[]
    {
        "feature",
        "first raw community comment",
        "first raw comment",
        "first community comment",
        "first comment",
        "raw community comment",
        "raw comment",
        "community comment",
        "comment",
        "original post",
    };
    private static void ValidateFileName(string pageName, string fileName, ref List<string> warnings)
    {
        if (!validFileNames.Contains(fileName))
        {
            warnings.Add(string.Format("PREP0100: The page '{0}' has filename '{1}' was not expected", pageName, fileName));
        }
    }

    private static void ValidateTemplate(string pageName, string fileName, string template, ref List<string> warnings)
    {
        var result = template
            .Replace("%%USERNAME%%", "aabbcc")
            .Replace("%%PAGENAME%%", "somepage")
            .Replace("%%FULLPAGENAME%%", "somepage")
            .Replace("%%YOURNAME%%", "ddeeff")
            .Replace("%%YOURFIRSTNAME%%", "Gghhii")
            .Replace("%%MEMBERLEVEL%%", "VIP Gold member")
            .Replace("%%STAFFLEVEL%%", "Admin");
        var lines = result.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        foreach (var line in lines)
        {
            if (line.Contains("%%"))
            {
                warnings.Add(string.Format("PREP0101: The page '{0}' has a file '{1}' has left over '%%' in this line:", pageName, fileName));
                warnings.Add(string.Format("          {0}", line));
            }
        }
    }
}

class PageCatalog
{
    public PageCatalog()
    {
        Pages = new List<Page>();
        Hubs = new Dictionary<string, IList<Page>>();
    }

    [JsonProperty(propertyName: "pages")]
    public IList<Page> Pages { get; private set; }
    // TODO andydragon - eventually need to remove the pages property altogether
    // public bool ShouldSerializePages()
    // {
    //     return Pages.Count > 0;
    // }

    [JsonProperty(propertyName: "hubs")]
    public IDictionary<string, IList<Page>> Hubs { get; private set; }
    // TODO andydragon - eventually need to uncomment this
    // public bool ShouldSerializeHubs()
    // {
    //     return Hubs.Count > 0;
    // }
}

class Page
{
    public Page(string name)
    {
        Name = name;
    }

    [JsonProperty(propertyName: "name")]
    public string Name { get; }

    [JsonProperty(propertyName: "pageName", NullValueHandling = NullValueHandling.Ignore)]
    public string? PageName { get; set; }
}

class Manifest
{
    public Manifest(string pageName)
    {
        PageName = pageName;
    }

    [JsonProperty(propertyName: "hub")]
    public string Hub { get; set; } = string.Empty;

    [JsonProperty(propertyName: "page")]
    public string Page { get; set; } = string.Empty;

    [JsonProperty(propertyName: "pageName")]
    public string PageName { get; set; } = string.Empty;
}

class TemplateCatalog
{
    public TemplateCatalog()
    {
        Pages = new List<TemplatePage>();
        SpecialTemplates = new List<Template>();
    }

    [JsonProperty(propertyName: "pages")]
    public IList<TemplatePage> Pages { get; private set; }

    [JsonProperty(propertyName: "specialTemplates")]
    public IList<Template> SpecialTemplates { get; private set; }
}

class TemplatePage
{
    public TemplatePage(string name, IDictionary<string, string> templates)
    {
        Name = name;
        Templates = templates.Keys.Select(template => new Template(template, templates[template])).ToList();
    }

    [JsonProperty(propertyName: "name")]
    public string Name { get; }

    [JsonProperty(propertyName: "templates")]
    public List<Template> Templates { get; }
}

class Template
{
    public Template(string name, string script)
    {
        Name = name;
        Script = script;
    }

    [JsonProperty(propertyName: "name")]
    public string Name { get; }

    [JsonProperty(propertyName: "template")]
    public string Script { get; }
}

class PageDirectoryComparer : IComparer<string>
{
    public int Compare(string? x, string? y)
    {
        if ((x ?? "").StartsWith("_") && (y ?? "").StartsWith("_"))
        {
            return string.Compare(x, y, StringComparison.OrdinalIgnoreCase);
        }
        if ((x ?? "").StartsWith("_"))
        {
            return 1;
        }
        if ((y ?? "").StartsWith("_"))
        {
            return -1;
        }
        return string.Compare(x, y, StringComparison.OrdinalIgnoreCase);
    }

    public static readonly PageDirectoryComparer Default = new();
}
