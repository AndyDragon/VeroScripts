﻿namespace PrepareTemplates;

class Program
{
    static void Main()
    {
        var cwd = Directory.GetCurrentDirectory();
        var templateCatalog = new TemplateCatalog();
        foreach (var folder in Directory.EnumerateDirectories(cwd).Order())
        {
            var templates = new Dictionary<string, string>();
            Console.WriteLine("Searching {0} folder...", folder);
            foreach (var file in Directory.EnumerateFiles(folder, "*.template").Order())
            {
                var fileName = Path.GetFileNameWithoutExtension(file);
                Console.WriteLine("\tAdding {0}...", file);
                templates.Add(fileName, File.ReadAllText(file));
            }
            if (templates.Count != 0)
            {
                var hubName = folder[(cwd.Length + 1)..];
                templateCatalog.Hubs.Add(new Hub(hubName, templates.Keys.ToList()));

                using var stringDict = File.CreateText(Path.Combine(cwd, hubName + ".stringsdict"));
                stringDict.WriteLine("<?xml version=\"1.0\" encoding=\"UTF-8\"?>");
                stringDict.WriteLine("<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">");
                stringDict.WriteLine("<plist version=\"1.0\">");
                stringDict.WriteLine("<dict>");
                foreach (var key in templates.Keys.Order())
                {
                    stringDict.WriteLine("\t<key>{0}</key>", key);
                    stringDict.WriteLine("\t<string>{0}</string>", templates[key]);
                }
                stringDict.WriteLine("</dict>");
                stringDict.WriteLine("</plist>");

                using var xcStrings = File.CreateText(Path.Combine(cwd, "new_" + hubName + ".xcstrings"));
                var strings = new StringsCatalog(templates);
                var result = Newtonsoft.Json.JsonConvert.SerializeObject(strings, Newtonsoft.Json.Formatting.Indented).Replace("\": \"", "\" : \"").Replace("\": {", "\" : {");
                xcStrings.WriteLine(result);
            }
        }
        using var catalogFile = File.CreateText(Path.Combine(cwd, "hubs.json"));
        var catalogJson = Newtonsoft.Json.JsonConvert.SerializeObject(templateCatalog, Newtonsoft.Json.Formatting.Indented);
        catalogFile.WriteLine(catalogJson);
    }
}

class TemplateCatalog
{
    public TemplateCatalog()
    {
        Hubs = new List<Hub>();
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "hubs")]
    public IList<Hub> Hubs { get; private set; }
}

class Hub
{
    public Hub(string name, List<string> templates)
    {
        Name = name;
        Templates = templates;
    }

    [Newtonsoft.Json.JsonProperty(propertyName: "name")]
    public string Name { get; }

    [Newtonsoft.Json.JsonProperty(propertyName: "templates")]
    public List<string> Templates { get; }
}

class StringsCatalog
{
    public StringsCatalog(IDictionary<string, string> templates)
    {
        SourceLanguage = "en";
        Strings = new Dictionary<string, StringsEntry>();
        foreach (var key in templates.Keys.Order())
        {
            Strings.Add(key, new StringsEntry(templates[key]));
        }
        Version = "1.0";
    }

    [Newtonsoft.Json.JsonProperty(PropertyName = "sourceLanguage")]
    public string SourceLanguage { get; private set; }

    [Newtonsoft.Json.JsonProperty(PropertyName = "strings")]
    public IDictionary<string, StringsEntry> Strings { get; private set; }

    [Newtonsoft.Json.JsonProperty(PropertyName = "version")]
    public string Version { get; private set; }
}

class StringsEntry
{
    public StringsEntry(string value)
    {
        ExtractionState = "manual";
        Localizations = new Localizations(value);
    }

    [Newtonsoft.Json.JsonProperty(PropertyName = "extractionState")]
    public string ExtractionState { get; private set; }

    [Newtonsoft.Json.JsonProperty(PropertyName = "localizations")]
    public Localizations Localizations { get; private set; }
}

class Localizations
{
    public Localizations(string value)
    {
        En = new LanguageUnit(value);
    }

    [Newtonsoft.Json.JsonProperty(PropertyName = "en")]
    public LanguageUnit En { get; private set; }
}

class LanguageUnit
{
    public LanguageUnit(string value)
    {
        StringUnit = new StringUnit(value);
    }

    [Newtonsoft.Json.JsonProperty(PropertyName = "stringUnit")]
    public StringUnit StringUnit { get; private set; }
}

class StringUnit
{
    public StringUnit(string value)
    {
        State = "translated";
        Value = value;
    }

    [Newtonsoft.Json.JsonProperty(PropertyName = "state")]
    public string State { get; private set; }

    [Newtonsoft.Json.JsonProperty(PropertyName = "value")]
    public string Value { get; private set; }
}