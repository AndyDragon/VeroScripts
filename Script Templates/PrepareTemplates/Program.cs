namespace PrepareTemplates;

class Program
{
    static void Main()
    {
        var cwd = Directory.GetCurrentDirectory();
        var templateCatalog = new HubsCatalogg();
        var warnings = new List<string>();
        foreach (var folder in Directory.EnumerateDirectories(cwd).OrderBy(dir => dir, HubDirectoryComparer.Default))
        {
            var hubName = folder[(cwd.Length + 1)..];
            var templates = new Dictionary<string, string>();
            Console.WriteLine("Searching {0} folder...", folder);
            foreach (var file in Directory.EnumerateFiles(folder, "*.template").Order())
            {
                var fileName = Path.GetFileNameWithoutExtension(file);
                ValidateFileName(hubName, fileName, ref warnings);
                Console.WriteLine("\tAdding {0}...", file);
                var template = File.ReadAllText(file);
                templates.Add(fileName, template);
                ValidateTemplate(hubName, fileName, template, ref warnings);
            }
            if (templates.Count != 0)
            {
                templateCatalog.Hubs.Add(new Hub(hubName, templates));
            }
        }
        using var catalogFile = File.CreateText(Path.Combine(cwd, "hubs.json"));
        var catalogJson = Newtonsoft.Json.JsonConvert.SerializeObject(templateCatalog, Newtonsoft.Json.Formatting.Indented);
        catalogFile.WriteLine(catalogJson);

        if (warnings.Count != 0)
        {
            Console.ForegroundColor = ConsoleColor.Yellow;
            foreach (var warning in warnings)
            {
                Console.WriteLine("{0}", warning);
            }
        }
    }

    private static readonly string[] validFileNames = new[]
    {
        "feature",
        "comment",
        "first comment",
        "community comment",
        "original post",
    };
    private static void ValidateFileName(string hubName, string fileName, ref List<string> warnings)
    {
        if (!validFileNames.Contains(fileName))
        {
            warnings.Add(string.Format("PREP0100: The hub '{0}' has filename '[1}' was not expected", hubName, fileName));
        }
    }

    private static void ValidateTemplate(string hubName, string fileName, string template, ref List<string> warnings)
    {
        var result = template
            .Replace("%%USERNAME%%", "aabbcc")
            .Replace("%%PAGENAME%%", "somepage")
            .Replace("%%YOURNAME%%", "ddeeff")
            .Replace("%%YOURFIRSTNAME%%", "Gghhii")
            .Replace("%%MEMBERLEVEL%%", "VIP Gold member")
            .Replace("%%STAFFLEVEL%%", "Admin");
        var lines = result.Split(new[] { '\n', '\r' }, StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        foreach (var line in lines)
        {
            if (line.Contains("%%"))
            {
                warnings.Add(string.Format("PREP0101: The hub '{0}' has a file '{1}' has left over '%%' in this line:", hubName, fileName));
                warnings.Add(string.Format("          {0}", line));
            }
        }
    }
}

class HubsCatalogg
{
    public HubsCatalogg()
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

class HubDirectoryComparer : IComparer<string>
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

    public static readonly HubDirectoryComparer Default = new();
}
