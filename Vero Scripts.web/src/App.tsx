/* eslint-disable react-hooks/exhaustive-deps */
import { useEffect, useRef, useState } from "react";
import "./App.css";
import {
  Checkbox,
  CommandButton,
  DefaultButton,
  Dialog,
  DialogFooter,
  DialogType,
  Dropdown,
  IDropdownOption,
  Label,
  PartialTheme,
  PrimaryButton,
  Separator,
  Stack,
  Text,
  TextField,
  ThemeProvider,
} from "@fluentui/react";
import { useBoolean } from "@fluentui/react-hooks";
import axios from "axios";
import { initializeIcons } from "@fluentui/font-icons-mdl2";
import { themeDictionary, defaultThemeKey } from "./themes";

// NOTE: Change the following to 'true' to use the testing scripts.
const scriptTesting = false;

initializeIcons();

interface Template {
  name: string;
  template: string;
}

interface TemplatePage {
  name: string;
  templates: Template[];
}

interface TemplateCatalog {
  pages: TemplatePage[];
  specialTemplates: Template[];
}

interface Page {
  name: string;
  pageName?: string;
  title?: string;
  hashTag?: string;
}

interface PageCatalog {
  hubs: Record<string, Page[]>;
}

const modalPropsStyles = { main: { maxWidth: 450 } };

function App() {
  const [currentTheme, setCurrentTheme] = useState<PartialTheme>(themeDictionary[defaultThemeKey].theme);
  const [selectedTheme, setSelectedTheme] = useState<string>("dark");
  const [selectedHub, setSelectedHub] = useState<string>();
  const [userName, setUserName] = useState<string>("");
  const [levelOptions, setLevelOptions] = useState<IDropdownOption[]>([]);
  const [selectedLevel, setSelectedLevel] = useState<string>("none");
  const [yourName, setYourName] = useState<string>("");
  const [firstName, setFirstName] = useState<string>("");
  const [pageOptions, setPageOptions] = useState<IDropdownOption[]>([]);
  const [selectedPage, setSelectedPage] = useState<string>("none");
  const [staffLevelOptions, setStaffLevelOptions] = useState<IDropdownOption[]>([]);
  const [selectedStaffLevel, setSelectedStaffLevel] = useState<string>("mod");
  const [isFirstFeature, setIsFirstFeature] = useState<boolean>(false);
  const [isRawTagCheckVisible, setIsRawTagCheckVisible] = useState<boolean>(false);
  const [isRawTag, setIsRawTag] = useState<boolean>(false);
  const [isCommunityTagCheckVisible, setIsCommunityTagCheckVisible] = useState<boolean>(false);
  const [isCommunityTag, setIsCommunityTag] = useState<boolean>(false);
  const [scriptValidationFailed, setScriptValidationFailed] = useState<boolean>(false);
  const [featureScript, setFeatureScript] = useState<string>("");
  const [commentScript, setCommentScript] = useState<string>("");
  const [originalPostScript, setOriginalPostScript] = useState<string>("");
  const [newLevelOptions, setNewLevelOptions] = useState<IDropdownOption[]>([]);
  const [selectedNewLevel, setSelectedNewLevel] = useState<string>("none");
  const [newLevelScriptValidationFailed, setNewLevelScriptValidationFailed] = useState<boolean>(false);
  const [newLevelScript, setNewLevelScript] = useState<string>("");
  const [hideDialog, { toggle: toggleHideDialog }] = useBoolean(true);
  const [placeholders, setPlaceholders] = useState<Record<string, string>>({});
  const pageCatalog = useRef<PageCatalog>({ hubs: {} });
  const templateCatalog = useRef<TemplateCatalog>({ pages: [], specialTemplates: [] });
  const scriptWithPlaceholders = useRef<string>("");
  const scriptWithPlaceholdersUntouched = useRef<string>("");

  const themeOptions: IDropdownOption[] = Object.keys(themeDictionary).map((key) => {
    return { key, text: themeDictionary[key].name, data: themeDictionary[key].theme };
  });

  const snapLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "artist", text: "Artist" },
    { key: "member", text: "Snap Member" },
    { key: "vip", text: "Snap VIP Member" },
    { key: "gold", text: "Snap VIP Gold Member" },
    { key: "platinum", text: "Snap Platinum Member" },
    { key: "elite", text: "Snap Elite Member" },
    { key: "hof", text: "Snap Hall of Fame Member" },
    { key: "diamond", text: "Snap Diamond Member" },
  ];

  const clickLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "artist", text: "Artist" },
    { key: "member", text: "Click Member" },
    { key: "bronze", text: "Click Bronze Member" },
    { key: "silver", text: "Click Silver Member" },
    { key: "gold", text: "Click Gold Member" },
    { key: "platinum", text: "Click Platinum Member" },
  ];

  const defaultLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "artist", text: "Artist" },
  ];

  const snapStaffLevelOptions: IDropdownOption[] = [
    { key: "mod", text: "Mod" },
    { key: "coadmin", text: "Co-admin" },
    { key: "admin", text: "Admin" },
    { key: "guestmod", text: "Guest moderator" },
  ];

  const defaultStaffLevelOptions: IDropdownOption[] = [
    { key: "mod", text: "Mod" },
    { key: "coadmin", text: "Co-admin" },
    { key: "admin", text: "Admin" },
  ];

  const snapNewLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "member feature", text: "Member (feature comment)" },
    { key: "member original post", text: "Member (original post comment)" },
    { key: "vip member feature", text: "VIP Member (feature comment)" },
    { key: "vip member original post", text: "VIP Member (original post comment)" },
  ];

  const clickNewLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "member", text: "Member" },
    { key: "bronze_member", text: "Bronze Member" },
    { key: "silver_member", text: "Silver Member" },
    { key: "gold_member", text: "Gold Member" },
    { key: "platinum_member", text: "Platinum Member" },
  ];

  const defaultNewLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
  ];

  useEffect(() => {
    document.title = "VERO Scripts";

    const themeKey = localStorage.getItem("theme") || defaultThemeKey;
    setSelectedTheme(themeKey);
    setCurrentTheme(themeDictionary[themeKey].theme || themeDictionary[defaultThemeKey].theme);
    setYourName(localStorage.getItem("yourname") || "");
    setFirstName(localStorage.getItem("firstname") || "");
    setSelectedPage(localStorage.getItem("page") || "None");
    setSelectedStaffLevel(localStorage.getItem("stafflevel") || "mod");

    // get the page catalog
    axios
      .get(scriptTesting
        ? "https://vero.andydragon.com/static/data/testing/pages.json"
        : "https://vero.andydragon.com/static/data/pages.json")
      .then((result) => {
        pageCatalog.current = result.data as PageCatalog;
        const options: IDropdownOption[] = [];
        options.push({ key: "none", text: "None" });
        Object.keys(pageCatalog.current.hubs).forEach(hub => {
          options.push(...pageCatalog.current.hubs[hub].map(page => ({
              key: hub + ":" + page.name,
              text: hub === "other" ? page.name : hub + "_" + page.name,
            })));
        });
        setPageOptions([...options.sort((a, b) => {
          if ((a.key as string).startsWith("other:") && (b.key as string).startsWith("other:")) {
            return (a.key as string).localeCompare(b.key as string);
          }
          if ((a.key as string).startsWith("other:")) {
            return 1;
          }
          if ((b.key as string).startsWith("other:")) {
            return -1;
          }
          if ((a.key as string) === "none" && (b.key as string) === "none") {
            return 0;
          }
          if ((a.key as string) === "none") {
            return -1;
          }
          if ((b.key as string) === "none") {
            return 1;
          }
          return (a.key as string).localeCompare(b.key as string);
        })]);

        // get the templates catalog
        axios
          .get(scriptTesting
            ? "https://vero.andydragon.com/static/data/testing/templates.json"
            : "https://vero.andydragon.com/static/data/templates.json")
          .then((result) => {
            templateCatalog.current = result.data as TemplateCatalog;
          })
          .catch((error) => console.error("Failed to get the templates: " + JSON.stringify(error)));
      })
      .catch((error) => console.error("Failed to get the pages: " + JSON.stringify(error)));
  }, []);

  useEffect(() => {
    let levelOptions = levelOptionsForPage();
    setLevelOptions(levelOptions);
    if (!levelOptions.find(option => option.key === selectedLevel)) {
      setSelectedLevel("none");
    }
    setNewLevelOptions(newLevelOptionsForPage());
    setSelectedNewLevel("none");
    let staffLevelOptions = staffLevelOptionsForPage();
    setStaffLevelOptions(staffLevelOptions);
    if (!staffLevelOptions.find(option => option.key === selectedStaffLevel)) {
      setSelectedStaffLevel("mod");
    }
    setIsRawTagCheckVisible(selectedHub === "snap");
    setIsCommunityTagCheckVisible(selectedHub === "snap");
  }, [selectedHub]);

  useEffect(() => {
    setSelectedHub(selectedPage.split(":")[0]);
  }, [selectedPage]);

  useEffect(() => {
    setPlaceholders({});
    const validationErrors: string[] = [];
    if (!userName) {
      validationErrors.push("User name is required");
    } else if (userName.startsWith("@")) {
      validationErrors.push("User name should not start with '@'");
    }
    if (!selectedLevel || selectedLevel === "none") {
      validationErrors.push("Member level is required");
    }
    if (!yourName) {
      validationErrors.push("Your user name is required");
    } else if (yourName.startsWith("@")) {
      validationErrors.push("Your user name should not start with '@'");
    }
    if (!firstName) {
      validationErrors.push("Your first name is required");
    }
    if (!selectedPage || selectedPage === "none") {
      validationErrors.push("Page is required");
    }
    setScriptValidationFailed(!!validationErrors.length);
    if (!pageCatalog.current || validationErrors.length !== 0) {
      const allErrors = validationErrors.join("\n");
      setFeatureScript(allErrors);
      setCommentScript("");
      setOriginalPostScript("");
    } else {
      const pageName = selectedPage || "";
      const templatePage = templateCatalog.current.pages.find((page) => page.name === selectedPage);
      if (templatePage) {
        setFeatureScript(prepareTemplate(getTemplate(templatePage, "feature"), pageName));
        setCommentScript(prepareTemplate(getTemplate(templatePage, "comment"), pageName));
        setOriginalPostScript(prepareTemplate(getTemplate(templatePage, "original post"), pageName));
      } else {
        setFeatureScript("Missing template page");
        setCommentScript("");
        setOriginalPostScript("");
      }
    }

    function getTemplate(page: TemplatePage, templateName: string) {
      // Check first feature and raw and community
      if (selectedHub === "snap" && isFirstFeature && isRawTag && isCommunityTag) {
        const firstCommunityTagTemplate = page.templates.find(
          (template) => template.name === "first raw community " + templateName
        )?.template;
        if (firstCommunityTagTemplate) {
          return firstCommunityTagTemplate;
        }
      }

      // Next check first feature and raw
      if (selectedHub === "snap" && isFirstFeature && isRawTag) {
        const firstCommunityTagTemplate = page.templates.find(
          (template) => template.name === "first raw " + templateName
        )?.template;
        if (firstCommunityTagTemplate) {
          return firstCommunityTagTemplate;
        }
      }

      // Next check first feature amd community
      if (selectedHub === "snap" && isFirstFeature && isCommunityTag) {
        const firstCommunityTagTemplate = page.templates.find(
          (template) => template.name === "first community " + templateName
        )?.template;
        if (firstCommunityTagTemplate) {
          return firstCommunityTagTemplate;
        }
      }

      // Next check first feature
      if (isFirstFeature) {
        const firstFeatureTemplate = page.templates.find(
          (template) => template.name === "first " + templateName
        )?.template;
        if (firstFeatureTemplate) {
          return firstFeatureTemplate;
        }
      }

      // Next check raw and community
      if (selectedHub === "snap" && isRawTag && isCommunityTag) {
        const communityTagTemplate = page.templates.find(
          (template) => template.name === "raw community " + templateName
        )?.template;
        if (communityTagTemplate) {
          return communityTagTemplate;
        }
      }

      // Next check raw
      if (selectedHub === "snap" && isRawTag) {
        const communityTagTemplate = page.templates.find(
          (template) => template.name === "raw " + templateName
        )?.template;
        if (communityTagTemplate) {
          return communityTagTemplate;
        }
      }

      // Next check community
      if (selectedHub === "snap" && isCommunityTag) {
        const communityTagTemplate = page.templates.find(
          (template) => template.name === "community " + templateName
        )?.template;
        if (communityTagTemplate) {
          return communityTagTemplate;
        }
      }

      // Last check standard
      const normalTemplate = page.templates.find((template) => template.name === templateName)?.template;
      if (normalTemplate) {
        return normalTemplate;
      }

      return "";
    }

    function prepareTemplate(template: string, pageName: string) {
      const parts = pageName.split(":");
      let hubPart = "";
      let pagePart = "";
      if (parts.length === 1) {
        hubPart = "snap";
        pagePart = parts[0];
      } else {
        hubPart = parts[0];
        pagePart = parts[1];
      }
      const page = pageCatalog.current.hubs[hubPart].find((page) => page.name === pagePart);
      const scriptPageName = page?.pageName || pagePart;
      const scriptPageTitle = page?.title || scriptPageName
      const scriptPageHash = page?.hashTag || scriptPageName
      const staffLevelString = staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || defaultStaffLevelOptions[0].text;
      let membership = levelOptions.find((option) => option.key === selectedLevel)?.text || "";
      if (hubPart === "snap" && membership.startsWith("Snap ")) {
        membership = membership.substring(5);
      }
      return (
        template
          .replaceAll("%%PAGENAME%%", scriptPageName)
          .replaceAll("%%FULLPAGENAME%%", pagePart)
          .replaceAll("%%PAGETITLE%%", scriptPageTitle)
          .replaceAll("%%PAGEHASH%%", scriptPageHash)
          .replaceAll("%%MEMBERLEVEL%%", membership)
          .replaceAll("%%USERNAME%%", userName)
          .replaceAll("%%YOURNAME%%", yourName)
          .replaceAll("%%YOURFIRSTNAME%%", firstName)
          .replaceAll("%%STAFFLEVEL%%", staffLevelString)
      );
    }
  }, [
    userName,
    selectedLevel,
    yourName,
    firstName,
    pageOptions,
    selectedPage,
    selectedStaffLevel,
    isFirstFeature,
    isRawTag,
    isCommunityTag,
  ]);

  function checkForPlaceholders(script: string, additionalScripts: string[], forceEdit?: boolean) {
    const placeholdersFound: string[] = [];
    const matches = script.matchAll(/\[\[([^\]]*)\]\]/g);
    [...matches].forEach((match) => {
      placeholdersFound.push(match[1]);
    });
    const placeholdersInScript = !!placeholdersFound.length;
    additionalScripts.forEach(additionalScript => {
      const matches = additionalScript.matchAll(/\[\[([^\]]*)\]\]/g);
      [...matches].forEach((match) => {
        placeholdersFound.push(match[1]);
      });
    });
    if (placeholdersInScript) {
      placeholdersFound.forEach((placeholderFound) => {
        if (!Object.keys(placeholders).includes(placeholderFound)) {
          placeholders[placeholderFound] = "";
        }
      });
      if (forceEdit) {
        toggleHideDialog();
        return true;
      }
    }
    return false;
  }

  async function copyScript(script: string, additionalScripts: string[], forceEdit?: boolean) {
    scriptWithPlaceholders.current = script;
    scriptWithPlaceholdersUntouched.current = script;
    if (!checkForPlaceholders(scriptWithPlaceholders.current, additionalScripts, forceEdit)) {
      await navigator.clipboard.writeText(scriptWithPlaceholders.current);
    }
  }

  function levelOptionsForPage() {
    if (selectedHub === "snap") {
      return snapLevelOptions;
    } else if (selectedHub === "click") {
      return clickLevelOptions;
    }
    return defaultLevelOptions;
  }

  function newLevelOptionsForPage() {
    if (selectedHub === "snap") {
      return snapNewLevelOptions;
    } else if (selectedHub === "click") {
      return clickNewLevelOptions;
    }
    return defaultNewLevelOptions;
  }

  function staffLevelOptionsForPage() {
    if (selectedHub === "snap") {
      return snapStaffLevelOptions;
    } else if (selectedHub === "click") {
      return defaultStaffLevelOptions;
    }
    return defaultStaffLevelOptions;
  }

  useEffect(() => {
    localStorage.setItem("theme", selectedTheme);
    localStorage.setItem("yourname", yourName);
    localStorage.setItem("firstname", firstName);
    localStorage.setItem("page", selectedPage);
    localStorage.setItem("stafflevel", selectedStaffLevel);
  }, [selectedTheme, yourName, firstName, selectedPage, selectedStaffLevel]);

  useEffect(() => {
    const validationErrors: string[] = [];
    if (selectedNewLevel !== "none" && !userName) {
      validationErrors.push("User name is required");
    }
    setNewLevelScriptValidationFailed(!!validationErrors.length);
    if (selectedNewLevel === "none" || !userName) {
      const allErrors = validationErrors.join("\n");
      setNewLevelScript(allErrors);
    } else {
      const pageName = selectedPage || "";
      const parts = pageName.split(":");
      let hubPart = "";
      let pagePart = "";
      if (parts.length === 1) {
        hubPart = "snap";
        pagePart = parts[0];
      } else {
        hubPart = parts[0];
        pagePart = parts[1];
      }
      const page = pageCatalog.current.hubs[hubPart].find((page) => page.name === pagePart);
      const scriptPageName = page?.pageName || pagePart;
      const scriptPageTitle = page?.title || scriptPageName
      const scriptPageHash = page?.hashTag || scriptPageName
      const template = templateCatalog.current.specialTemplates.find(template => {
        if (hubPart === "snap") {
          return template.name === selectedHub + ":" + selectedNewLevel.toLowerCase();
        } else {
          return template.name === selectedHub + ":" + selectedNewLevel.replaceAll(" ", "_").toLowerCase();
        }
      });
      const staffLevelString = staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || defaultStaffLevelOptions[0].text;
      const script = (template?.template || "")
        .replaceAll("%%PAGENAME%%", scriptPageName)
        .replaceAll("%%FULLPAGENAME%%", pagePart)
        .replaceAll("%%PAGETITLE%%", scriptPageTitle)
        .replaceAll("%%PAGEHASH%%", scriptPageHash)
        .replaceAll("%%USERNAME%%", userName)
        .replaceAll("%%YOURNAME%%", yourName)
        .replaceAll("%%YOURFIRSTNAME%%", firstName)
        .replaceAll("%%STAFFLEVEL%%", staffLevelString);
      setNewLevelScript(script);
    }
  }, [
    selectedHub,
    userName,
    selectedLevel,
    yourName,
    firstName,
    pageOptions,
    selectedPage,
    selectedStaffLevel,
    isFirstFeature,
    isRawTag,
    isCommunityTag,
    selectedNewLevel
  ]);

  return (
    <ThemeProvider applyTo="body" theme={currentTheme}>
      <div className="App">
        <header className="App-header">
          <Stack
            horizontal
            horizontalAlign="space-between"
            style={{
              backgroundColor: currentTheme.palette?.themeTertiary,
              color: currentTheme.palette?.themeDarker,
            }}
          >
            {/* Title */}
            <Text
              variant="large"
              style={{
                margin: "18px 8px 18px 20px",
                fontWeight: "bolder",
              }}
            >
              VERO Scripts
            </Text>
            <Dropdown
              options={themeOptions}
              selectedKey={selectedTheme || defaultThemeKey}
              onChange={(_, item) => {
                setSelectedTheme((item?.key as string) || defaultThemeKey);
                setCurrentTheme(item?.data || themeDictionary[defaultThemeKey].theme);
              }}
              style={{
                margin: "13px 10px 10px 10px",
                minWidth: "200px",
              }}
            />
          </Stack>
        </header>

        <div className="App-body">
          <Stack>
            {/* Page editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "40px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color:
                    ((selectedPage || "none") === "none" || !selectedPage)
                      ? currentTheme.semanticColors?.errorText
                      : currentTheme.semanticColors?.bodyText,
                }}
              >
                Page:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <Dropdown
                  options={pageOptions}
                  selectedKey={selectedPage || "None"}
                  onChange={(_, item) => {
                    setSelectedPage((item?.key as string) || "None");
                    setLevelOptions(levelOptionsForPage());
                  }}
                  style={{ minWidth: "160px" }}
                />
              </Stack.Item>
            </Stack>

            {/* Page staff level editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "60px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color: !selectedStaffLevel
                    ? currentTheme.semanticColors?.errorText
                    : currentTheme.semanticColors?.bodyText,
                }}
              >
                Staff level:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <Dropdown
                  options={staffLevelOptions}
                  selectedKey={selectedStaffLevel || "mod"}
                  onChange={(_, item) => setSelectedStaffLevel((item?.key as string) || "mod")}
                  style={{ minWidth: "200px" }}
                />
              </Stack.Item>
            </Stack>

            {/* Your name editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "40px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color: !yourName || yourName.startsWith("@") ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
                }}
              >
                You:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <TextField
                  value={yourName}
                  onChange={(_, newValue) => setYourName(newValue || "")}
                  style={{ minWidth: "200px" }}
                  autoCapitalize="off"
                  placeholder="Enter your user name (do not include '@')"
                />
              </Stack.Item>
            </Stack>

            {/* Your first name editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "92px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color: !firstName ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
                }}
              >
                Your first name:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <TextField
                  value={firstName}
                  onChange={(_, newValue) => setFirstName(newValue || "")}
                  style={{ minWidth: "200px" }}
                  placeholder="Enter your first name"
                />
              </Stack.Item>
            </Stack>

            {/* User name editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "40px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color: !userName || userName.startsWith("@") ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
                }}
              >
                User:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <TextField
                  value={userName}
                  onChange={(_, newValue) => setUserName(newValue || "")}
                  style={{ minWidth: "200px" }}
                  autoCapitalize="off"
                  placeholder="Enter the user name (do not include '@')"
                />
              </Stack.Item>
            </Stack>

            {/* User level editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  minWidth: "40px",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                  fontWeight: "bold",
                  color:
                    (selectedLevel || "none") === "none"
                      ? currentTheme.semanticColors?.errorText
                      : currentTheme.semanticColors?.bodyText,
                }}
              >
                Level:
              </Label>
              <Stack.Item grow={1} shrink={1}>
                <Dropdown
                  options={levelOptions}
                  selectedKey={selectedLevel || "none"}
                  onChange={(_, item) => setSelectedLevel((item?.key as string) || "none")}
                  style={{ minWidth: "200px" }}
                />
              </Stack.Item>
            </Stack>

            {/* Options */}
            <Stack horizontal style={{ width: "100%", paddingLeft: "8px" }} tokens={{ childrenGap: "8px" }}>
              <Checkbox
                label="First feature on page"
                checked={isFirstFeature}
                onChange={(_, newValue) => setIsFirstFeature(!!newValue)}
                styles={{
                  text: { fontWeight: "bold" },
                }}
              />
              {isRawTagCheckVisible &&
                (
                  <Checkbox
                    label="RAW tag"
                    checked={isRawTag}
                    onChange={(_, newValue) => setIsRawTag(!!newValue)}
                    styles={{
                      text: { fontWeight: "bold" },
                    }}
                  />
                )
              }
              {isCommunityTagCheckVisible &&
                (
                  <Checkbox
                    label="Community tag"
                    checked={isCommunityTag}
                    onChange={(_, newValue) => setIsCommunityTag(!!newValue)}
                    styles={{
                      text: { fontWeight: "bold" },
                    }}
                  />
                )
              }
          </Stack>

            <Separator />

            {/* Feature script editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                }}
              >
                Feature script:
              </Label>
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy"
                onClick={async () => {
                  await copyScript(featureScript, [commentScript, originalPostScript], true);
                }}
                disabled={scriptValidationFailed || !featureScript}
              />
            </Stack>
            <TextField
              multiline
              rows={12}
              value={featureScript}
              onChange={(_, newValue) => setFeatureScript(newValue || "")}
              readOnly={scriptValidationFailed || !featureScript}
              style={{
                color: scriptValidationFailed ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
              }}
            />

            <Separator />

            {/* Comment script editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                }}
              >
                Comment script:
              </Label>
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy"
                onClick={async () => {
                  await copyScript(commentScript, [featureScript, originalPostScript], true);
                }}
                disabled={scriptValidationFailed || !commentScript}
              />
            </Stack>
            <TextField
              multiline
              rows={6}
              value={commentScript}
              onChange={(_, newValue) => setCommentScript(newValue || "")}
              readOnly={scriptValidationFailed || !commentScript}
              style={{
                color: scriptValidationFailed ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
              }}
            />

            <Separator />

            {/* Original post script editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                }}
              >
                Original post script:
              </Label>
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy"
                onClick={async () => {
                  await copyScript(originalPostScript, [featureScript, commentScript], true);
                }}
                disabled={scriptValidationFailed || !originalPostScript}
              />
            </Stack>
            <TextField
              multiline
              rows={3}
              value={originalPostScript}
              onChange={(_, newValue) => setOriginalPostScript(newValue || "")}
              readOnly={scriptValidationFailed || !originalPostScript}
              style={{
                color: scriptValidationFailed ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
              }}
            />

            <Separator />

            {/* New membership level script editor */}
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Label
                style={{
                  width: "auto",
                  margin: "4px 8px",
                  textAlign: "left",
                  whiteSpace: "nowrap",
                }}
              >
                New membership:
              </Label>
            </Stack>
            <Stack horizontal style={{ width: "100%" }} tokens={{ childrenGap: "8px" }}>
              <Dropdown
                options={newLevelOptions}
                selectedKey={selectedNewLevel || "none"}
                onChange={(_, item) => setSelectedNewLevel((item?.key as string) || "none")}
                style={{ width: selectedHub === "snap" ? "280px" : "160px" }}
              />
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy"
                onClick={async () => await navigator.clipboard.writeText(newLevelScript)}
                disabled={newLevelScriptValidationFailed || !newLevelScript}
                />
            </Stack>
            <TextField
              multiline
              rows={6}
              value={newLevelScript}
              onChange={(_, newValue) => setNewLevelScript(newValue || "")}
              readOnly={newLevelScriptValidationFailed || !newLevelScript}
              style={{
                color: newLevelScriptValidationFailed ? currentTheme.semanticColors?.errorText : currentTheme.semanticColors?.bodyText,
              }}
            />
            <Separator />
          </Stack>
        </div>
      </div>
      <Dialog
        hidden={hideDialog}
        onDismiss={toggleHideDialog}
        dialogContentProps={{
          type: DialogType.close,
          title: "Manual placeholders",
          subText: "There are manual placeholders that need to be filled out:",
        }}
        modalProps={{
          isBlocking: true,
          styles: modalPropsStyles,
        }}
      >
        {Object.keys(placeholders).map((key) => (
          <TextField
            key={key}
            label={key}
            value={placeholders[key]}
            onChange={(_, newValue) => {
              const newPlaceholders: Record<string, string> = { ...placeholders };
              newPlaceholders[key] = newValue || "";
              setPlaceholders(newPlaceholders);
            }}
          />
        ))}
        <hr />
        <DialogFooter>
          <PrimaryButton
            onClick={async () => {
              let scriptToCopy = scriptWithPlaceholdersUntouched.current;
              Object.keys(placeholders).forEach((placeholder) => {
                const placeholderRegEx = new RegExp("\\[\\[" + placeholder + "\\]\\]", "g");
                scriptToCopy = scriptToCopy.replaceAll(placeholderRegEx, placeholders[placeholder]);
              });
              await navigator.clipboard.writeText(scriptToCopy);
              toggleHideDialog();
            }}
            text="Copy"
          />
          <DefaultButton
            onClick={async () => {
              await navigator.clipboard.writeText(scriptWithPlaceholdersUntouched.current);
              toggleHideDialog();
            }}
            text="Copy with placeholders"
          />
        </DialogFooter>
      </Dialog>
    </ThemeProvider>
  );
}

export default App;
