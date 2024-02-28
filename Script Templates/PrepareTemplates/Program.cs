namespace PrepareTemplates;

class Program
{
    static void Main()
    {
        var originalForeground = Console.ForegroundColor;
        var cwd = Directory.GetCurrentDirectory();
        var pageCatalog = new PageCatalog();
        var templateCatalog = new TemplateCatalog();
        var hubCatalog = new HubCatalog();
        var warnings = new List<string>();
        foreach (var folder in Directory.EnumerateDirectories(cwd).OrderBy(dir => dir, PageDirectoryComparer.Default))
        {
            var pageName = folder[(cwd.Length + 1)..];
            var templates = new Dictionary<string, string>();
            Console.WriteLine("Searching {0} folder...", folder);
            foreach (var file in Directory.EnumerateFiles(folder, "*.template").Order())
            {
                var fileName = Path.GetFileNameWithoutExtension(file);
                if (!string.Equals(pageName, "$"))
                {
                    ValidateFileName(pageName, fileName, ref warnings);
                }
                Console.WriteLine("\tAdding {0}...", file);
                var template = File.ReadAllText(file);
                templates.Add(fileName, template);
                ValidateTemplate(pageName, fileName, template, ref warnings);
            }
            if (templates.Count != 0)
            {
                if (string.Equals(pageName, "$"))
                {
                    // Add special templates to template catalog.
                    foreach (var key in templates.Keys)
                    {
                        templateCatalog.SpecialTemplates.Add(new Template(key, templates[key]));
                    }
                }
                else
                {
                    // Add page to all the catalogs.
                    var page = new Page(pageName);
                    var foundManifest = false;
                    if (File.Exists(Path.Combine(folder, "manifest.json")))
                    {
                        var manifestFile = File.ReadAllText(Path.Combine(folder, "manifest.json"));
                        page.PageName = Newtonsoft.Json.JsonConvert.DeserializeObject<Manifest>(manifestFile)?.PageName;
                        foundManifest = true;
                    }
                    pageCatalog.Pages.Add(page);
                    templateCatalog.Pages.Add(new TemplatePage(pageName, templates));
                    if (!foundManifest)
                    {
                        // Hub file (old style) does not include pages with a manifest.
                        hubCatalog.Hubs.Add(new Hub(pageName, templates));
                    }
                }
            }
        }
        using var pageCatalogFile = File.CreateText(Path.Combine(cwd, "pages.json"));
        var pageCatalogJson = Newtonsoft.Json.JsonConvert.SerializeObject(pageCatalog/*, Newtonsoft.Json.Formatting.Indented*/); // minimize
        pageCatalogFile.WriteLine(pageCatalogJson);
        using var templateCatalogFile = File.CreateText(Path.Combine(cwd, "templates.json"));
        var templateCatalogJson = Newtonsoft.Json.JsonConvert.SerializeObject(templateCatalog, Newtonsoft.Json.Formatting.Indented);
        templateCatalogFile.WriteLine(templateCatalogJson);
        using var hubCatalogFile = File.CreateText(Path.Combine(cwd, "hubs.json"));
        var hubCatalogJson = Newtonsoft.Json.JsonConvert.SerializeObject(hubCatalog, Newtonsoft.Json.Formatting.Indented);
        hubCatalogFile.WriteLine(hubCatalogJson);

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

    private static readonly string[] validFileNames = new[]
    {
        "feature",
        "comment",
        "first comment",
        "community comment",
        "first community comment",
        "raw comment",
        "first raw comment",
        "original post",
    };
    private static void ValidateFileName(string pageName, string fileName, ref List<string> warnings)
    {
        if (!validFileNames.Contains(fileName))
        {
            warnings.Add(string.Format("PREP0100: The page '{0}' has filename '[1}' was not expected", pageName, fileName));
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
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "pages")]
    public IList<Page> Pages { get; private set; }
}

class Page
{
    public Page(string name)
    {
        Name = name;
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "name")]
    public string Name { get; }

    [Newtonsoft.Json.JsonProperty(propertyName: "pageName", NullValueHandling = Newtonsoft.Json.NullValueHandling.Ignore)]
    public string? PageName { get; set; }
}

class Manifest
{
    public Manifest(string pageName)
    {
        PageName = pageName;
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "pageName")]
    public string PageName { get; set; }
}

class HubCatalog
{
    public HubCatalog()
    {
        Hubs = new List<Hub>();
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "hubs")]
    public IList<Hub> Hubs { get; private set; }
}

class Hub
{
    public Hub(string name, IDictionary<string, string> templates)
    {
        Name = name;
        Templates = templates.Keys.Select(template => new Template(template, templates[template])).ToList();
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "name")]
    public string Name { get; }

    [Newtonsoft.Json.JsonProperty(propertyName: "templates")]
    public List<Template> Templates { get; }
}

class TemplateCatalog
{
    public TemplateCatalog()
    {
        Pages = new List<TemplatePage>();
        SpecialTemplates = new List<Template>();
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "pages")]
    public IList<TemplatePage> Pages { get; private set; }

    [Newtonsoft.Json.JsonProperty(propertyName: "specialTemplates")]
    public IList<Template> SpecialTemplates { get; private set; }
}

class TemplatePage
{
    public TemplatePage(string name, IDictionary<string, string> templates)
    {
        Name = name;
        Templates = templates.Keys.Select(template => new Template(template, templates[template])).ToList();
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "name")]
    public string Name { get; }

    [Newtonsoft.Json.JsonProperty(propertyName: "templates")]
    public List<Template> Templates { get; }
}

class Template
{
    public Template(string name, string script)
    {
        Name = name;
        Script = script;
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "name")]
    public string Name { get; }

    [Newtonsoft.Json.JsonProperty(propertyName: "template")]
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
