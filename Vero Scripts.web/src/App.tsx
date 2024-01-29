/* eslint-disable react-hooks/exhaustive-deps */
import { useEffect, useRef, useState } from "react";
import "./App.css";
import {
  Checkbox,
  CommandButton,
  Dropdown,
  IDropdownOption,
  Label,
  Separator,
  Stack,
  TextField,
} from "@fluentui/react";
import axios from "axios";
import { initializeIcons } from '@fluentui/font-icons-mdl2';

initializeIcons();

interface Template {
  name: string;
  template: string;
}

interface Page {
  name: string;
  templates: Template[];
}

interface Pages {
  hubs: Page[];
}

function App() {
  const [userName, setUserName] = useState<string | undefined>("");
  const [selectedLevel, setSelectedLevel] = useState<string>("none");
  const [yourName, setYourName] = useState<string | undefined>("andydragon");
  const [firstName, setFirstName] = useState<string | undefined>("Andy");
  const [pageOptions, setPageOptions] = useState<IDropdownOption[]>([]);
  const [selectedPage, setSelectedPage] = useState<string>("longexposure");
  const [customPage, setCustomPage] = useState<string | undefined>("");
  const [selectedStaffLevel, setSelectedStaffLevel] = useState<string>("mod");
  const [isFirstFeature, setIsFirstFeature] = useState<boolean>(false);
  const [isCommunityTag, setIsCommunityTag] = useState<boolean>(false);
  const [featureScript, setFeatureScript] = useState<string>("");
  const [commentScript, setCommentScript] = useState<string>("");
  const [originalPostScript, setOriginalPostScript] = useState<string>("");
  const [selectedNewLevel, setSelectedNewLevel] = useState<string>("none");
  const [newLevelScript, setNewLevelScript] = useState<string>("");
  const pages = useRef<Pages>();

  const levelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "artist", text: "Artist" },
    { key: "member", text: "Member" },
    { key: "vip", text: "VIP Member" },
    { key: "gold", text: "VIP Gold Member" },
    { key: "platinum", text: "Platinum Member" },
    { key: "elite", text: "Elite Member" },
    { key: "hof", text: "Hall of Fame Member" },
    { key: "diamond", text: "Diamond Member" },
  ];

  const staffLevelOptions: IDropdownOption[] = [
    { key: "mod", text: "Mod" },
    { key: "coadmin", text: "Co-admin" },
    { key: "admin", text: "Admin" },
  ];

  const newLevelOptions: IDropdownOption[] = [
    { key: "none", text: "None" },
    { key: "member", text: "Member" },
    { key: "vip", text: "VIP member" },
  ];

  useEffect(() => {
    document.title = "VERO Scripts";

    setYourName(localStorage.getItem("yourname") || "");
    setFirstName(localStorage.getItem("firstname") || "");
    setSelectedPage(localStorage.getItem("page") || "default");
    setCustomPage(localStorage.getItem("custompage") || "");
    setSelectedStaffLevel(localStorage.getItem("stafflevel") || "mod");

    axios
      .get("https://andydragon.com/depot/VERO/hubs.json")
      .then((result) => {
        pages.current = result.data as Pages;
        setPageOptions([
          ...pages.current.hubs.map((hub) => ({
            key: hub.name,
            text: hub.name,
          })),
        ]);
      })
      .catch((error) =>
        console.error("Failed to get the pages: " + JSON.stringify(error))
      );
  }, []);

  useEffect(() => {
    if (
      !pages.current ||
      !userName ||
      (selectedLevel || "none") === "none" ||
      !yourName ||
      !firstName ||
      ((selectedPage || "default") === "default" && !customPage)
    ) {
      setFeatureScript("");
      setCommentScript("");
      setOriginalPostScript("");
    } else {
      const pageName = (((selectedPage || "default") === "default") ? customPage : selectedPage) || "";
      const page = pages.current.hubs.find(
        (hub) => hub.name === (selectedPage || "default")
      );
      if (page) {
        setFeatureScript(getTemplate(page, "feature")
          .replaceAll("%%PAGENAME%%", pageName)
          .replaceAll("%%USERNAME%%", userName)
          .replaceAll("%%MEMBERLEVEL%%", levelOptions.find((option) => option.key === selectedLevel)?.text || "")
          .replaceAll("%%YOURNAME%%", yourName)
          .replaceAll("%%YOURFIRSTNAME%%", firstName)
          // Special case for 'YOUR FIRST NAME' since it's now autofilled.
          .replaceAll("[[YOUR FIRST NAME]]", firstName)
          .replaceAll("%%STAFFLEVEL%%", staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || ""));
        setCommentScript(getTemplate(page, "comment")
          .replaceAll("%%PAGENAME%%", pageName)
          .replaceAll("%%USERNAME%%", userName)
          .replaceAll("%%MEMBERLEVEL%%", levelOptions.find((option) => option.key === selectedLevel)?.text || "")
          .replaceAll("%%YOURNAME%%", yourName)
          .replaceAll("%%YOURFIRSTNAME%%", firstName)
          // Special case for 'YOUR FIRST NAME' since it's now autofilled.
          .replaceAll("[[YOUR FIRST NAME]]", firstName)
          .replaceAll("%%STAFFLEVEL%%", staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || ""));
        setOriginalPostScript(getTemplate(page, "original post")
          .replaceAll("%%PAGENAME%%", pageName)
          .replaceAll("%%USERNAME%%", userName)
          .replaceAll("%%MEMBERLEVEL%%", levelOptions.find((option) => option.key === selectedLevel)?.text || "")
          .replaceAll("%%YOURNAME%%", yourName)
          .replaceAll("%%YOURFIRSTNAME%%", firstName)
          // Special case for 'YOUR FIRST NAME' since it's now autofilled.
          .replaceAll("[[YOUR FIRST NAME]]", firstName)
          .replaceAll("%%STAFFLEVEL%%", staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || ""));
      } else {
        setFeatureScript("");
        setCommentScript("");
        setOriginalPostScript("");
      }
    }

    function getTemplate(page: Page, templateName: string) {
      if (isCommunityTag) {
        const communityTagTemplate = page.templates.find((template) => template.name === "community " + templateName)?.template;
        if (communityTagTemplate) {
          return communityTagTemplate;
        }
      }
      if (isFirstFeature) {
        const firstFeatureTemplate = page.templates.find((template) => template.name === "first " + templateName)?.template;
        if (firstFeatureTemplate) {
          return firstFeatureTemplate;
        }
      }
      const normalTemplate = page.templates.find((template) => template.name === templateName)?.template;
      if (normalTemplate) {
        return normalTemplate;
      }
      return page.templates.find((template) => template.name === "default")?.template || "";
    }
  }, [
    userName,
    selectedLevel,
    yourName,
    firstName,
    pageOptions,
    selectedPage,
    customPage,
    selectedStaffLevel,
    isFirstFeature,
    isCommunityTag,
  ]);

  useEffect(() => {
    localStorage.setItem("yourname", yourName || "");
    localStorage.setItem("firstname", firstName || "");
    localStorage.setItem("page", selectedPage || "");
    localStorage.setItem("custompage", customPage || "");
    localStorage.setItem("stafflevel", selectedStaffLevel || "");
  }, [yourName, firstName, selectedPage, customPage, selectedStaffLevel]);

  useEffect(() => {
    if (selectedNewLevel === "none" || !userName) {
        setNewLevelScript("");
    } else if (selectedNewLevel === "member") {
        setNewLevelScript(
            "Congratulations @" + userName + " on your 5th feature!\n" +
            "\n" +
            "I took the time to check the number of features you have with the SNAP Community and wanted to share with you that you are now a Member of the SNAP Community!\n" +
            "\n" +
            "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
            "\n" +
            "Please consider adding ✨ SNAP Community Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag.\n");
    } else if (selectedNewLevel === "vip") {
        setNewLevelScript(
            "Congratulations @" + userName + " on your 15th feature!\n" +
            "\n" +
            "I took the time to check the number of features you have with the SNAP Community and wanted to share that you are now a VIP Member of the SNAP Community!\n" +
            "\n" +
            "That's an awesome achievement 👏🏼👏🏼💐💐💐💐💐💐.\n" +
            "\n" +
            "Please consider adding ✨ SNAP VIP Member ✨ to your bio it will give you the chance to be featured in any raw page using only the membership tag.");
    }
  }, [
    userName,
    selectedNewLevel,
  ]);

  return (
    <div className="App">
      <header className="App-header">
        <Stack>
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
              style={{ width: "60px", margin: "4px 8px", textAlign: "right" }}
            >
              User:
            </Label>
            <TextField
              value={userName}
              onChange={(_, newValue) => setUserName(newValue)}
              style={{ width: "400px" }}
            />
          </Stack>
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
              style={{ width: "60px", margin: "4px 8px", textAlign: "right" }}
            >
              Level:
            </Label>
            <Dropdown
              options={levelOptions}
              selectedKey={selectedLevel || "none"}
              onChange={(_, item) =>
                setSelectedLevel((item?.key as string) || "none")
              }
              style={{ width: "400px" }}
            />
          </Stack>
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
              style={{ width: "60px", margin: "4px 8px", textAlign: "right" }}
            >
              You:
            </Label>
            <TextField
              value={yourName}
              onChange={(_, newValue) => setYourName(newValue)}
              style={{ width: "200px" }}
            />
            <Label
              style={{ width: "80px", margin: "4px 8px", textAlign: "right" }}
            >
              First name:
            </Label>
            <TextField
              value={firstName}
              onChange={(_, newValue) => setFirstName(newValue)}
              style={{ width: "200px" }}
            />
          </Stack>
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
              style={{ width: "60px", margin: "4px 8px", textAlign: "right" }}
            >
              Page:
            </Label>
            <Dropdown
              options={pageOptions}
              selectedKey={selectedPage || "default"}
              onChange={(_, item) =>
                setSelectedPage((item?.key as string) || "default")
              }
              style={{ width: "400px" }}
            />
            <TextField
              value={customPage}
              onChange={(_, newValue) => setCustomPage(newValue)}
              style={{ width: "200px" }}
              disabled={(selectedPage || "default") !== "default"}
            />
            <Label
              style={{ width: "80px", margin: "4px 8px", textAlign: "right" }}
            >
              Staff level:
            </Label>
            <Dropdown
              options={staffLevelOptions}
              selectedKey={selectedStaffLevel || "mod"}
              onChange={(_, item) =>
                setSelectedStaffLevel((item?.key as string) || "mod")
              }
              style={{ width: "400px" }}
            />
            <Checkbox
              label="First feature on page"
              checked={isFirstFeature}
              onChange={(_, newValue) => setIsFirstFeature(!!newValue)}
            />
            <Checkbox
              label="Community tag"
              checked={isCommunityTag}
              onChange={(_, newValue) => setIsCommunityTag(!!newValue)}
            />
          </Stack>
          <Separator />
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
                style={{ width: "auto", margin: "4px 8px", textAlign: "right" }}
              >
              Feature script:
            </Label>
            <CommandButton
              iconProps={{iconName: "Copy"}}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(featureScript)}
              disabled={!featureScript}
            />
          </Stack>
          <TextField
            multiline
            rows={12}
            value={featureScript}
            onChange={(_, newValue) => setFeatureScript(newValue || "")}
          />
          <Separator />
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
                style={{ width: "auto", margin: "4px 8px", textAlign: "right" }}
              >
              Comment script:
            </Label>
            <CommandButton
              iconProps={{iconName: "Copy"}}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(commentScript)}
              disabled={!commentScript}
            />
          </Stack>
          <TextField
            multiline
            rows={6}
            value={commentScript}
            onChange={(_, newValue) => setCommentScript(newValue || "")}
          />
          <Separator />
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
                style={{ width: "auto", margin: "4px 8px", textAlign: "right" }}
              >
              Original post script:
            </Label>
            <CommandButton
              iconProps={{iconName: "Copy"}}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(originalPostScript)}
              disabled={!originalPostScript}
            />
          </Stack>
          <TextField
            multiline
            rows={3}
            value={originalPostScript}
            onChange={(_, newValue) => setOriginalPostScript(newValue || "")}
          />
          <Separator />
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "16px" }}
          >
            <Label
                style={{ width: "auto", margin: "4px 8px", textAlign: "right" }}
              >
              New membership:
            </Label>
            <Dropdown
              options={newLevelOptions}
              selectedKey={selectedNewLevel || "none"}
              onChange={(_, item) =>
                setSelectedNewLevel((item?.key as string) || "mod")
              }
              style={{ width: "200px" }}
            />
            <CommandButton
              iconProps={{iconName: "Copy"}}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(newLevelScript)}
              disabled={!newLevelScript}
            />
          </Stack>
          <TextField
            multiline
            rows={6}
            value={newLevelScript}
            onChange={(_, newValue) => setNewLevelScript(newValue || "")}
          />
          <Separator />
        </Stack>
      </header>
    </div>
  );
}

export default App;
