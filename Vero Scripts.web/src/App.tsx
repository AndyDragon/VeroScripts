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
  Text,
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
  const [userName, setUserName] = useState<string>("");
  const [selectedLevel, setSelectedLevel] = useState<string>("none");
  const [yourName, setYourName] = useState<string>("andydragon");
  const [firstName, setFirstName] = useState<string>("Andy");
  const [pageOptions, setPageOptions] = useState<IDropdownOption[]>([]);
  const [selectedPage, setSelectedPage] = useState<string>("longexposure");
  const [customPage, setCustomPage] = useState<string>("");
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
        setFeatureScript(prepareTemplate(getTemplate(page, "feature"), pageName));
        setCommentScript(prepareTemplate(getTemplate(page, "comment"), pageName));
        setOriginalPostScript(prepareTemplate(getTemplate(page, "original post"), pageName));
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

    function prepareTemplate(template: string, pageName: string) {
      return template
        .replaceAll("%%PAGENAME%%", pageName)
        .replaceAll("%%USERNAME%%", userName)
        .replaceAll("%%MEMBERLEVEL%%", levelOptions.find((option) => option.key === selectedLevel)?.text || "")
        .replaceAll("%%YOURNAME%%", yourName)
        .replaceAll("%%YOURFIRSTNAME%%", firstName)
        // Special case for 'YOUR FIRST NAME' since it's now autofilled.
        .replaceAll("[[YOUR FIRST NAME]]", firstName)
        .replaceAll("%%STAFFLEVEL%%", staffLevelOptions.find((option) => option.key === selectedStaffLevel)?.text || "");
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
    localStorage.setItem("yourname", yourName);
    localStorage.setItem("firstname", firstName);
    localStorage.setItem("page", selectedPage);
    localStorage.setItem("custompage", customPage);
    localStorage.setItem("stafflevel", selectedStaffLevel);
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
          {/* Title */}
          <Text
            variant="large"
            style={{
              color: "cornflowerblue",
              marginBottom: "10px",
            }}
          >
            VERO Scripts
          </Text>

          {/* User name editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "40px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: !userName ? "red" : "white",
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
                placeholder="Enter the user name"
              />
            </Stack.Item>
          </Stack>

          {/* User level editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "40px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: ((selectedLevel || "none") === "none") ? "red" : "white",
              }}
            >
              Level:
            </Label>
            <Stack.Item grow={1} shrink={1}>
              <Dropdown
                options={levelOptions}
                selectedKey={selectedLevel || "none"}
                onChange={(_, item) =>
                  setSelectedLevel((item?.key as string) || "none")
                }
                style={{ minWidth: "200px" }}
              />
            </Stack.Item>
          </Stack>

          {/* Your name editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "40px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: !yourName ? "red" : "white",
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
                placeholder="Enter your user name"
              />
            </Stack.Item>
          </Stack>

          {/* Your first name editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "92px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: !firstName ? "red" : "white",
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

          {/* Page editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "40px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: ((selectedPage || "default") === "default") ? (!customPage ? "red" : undefined) : "white",
              }}
            >
              Page:
            </Label>
            <Stack.Item grow={1} shrink={1}>
              <Dropdown
                options={pageOptions}
                selectedKey={selectedPage || "default"}
                onChange={(_, item) =>
                  setSelectedPage((item?.key as string) || "default")
                }
                style={{ minWidth: "160px" }}
              />
            </Stack.Item>
            <Stack.Item grow={1} shrink={1}>
              <TextField
                value={customPage}
                onChange={(_, newValue) => setCustomPage(newValue || "")}
                style={{ minWidth: "80px" }}
                autoCapitalize="off"
                disabled={(selectedPage || "default") !== "default"}
              />
            </Stack.Item>
          </Stack>

          {/* Page staff level editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                minWidth: "60px",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                fontWeight: "bold",
                color: !selectedStaffLevel ? "red" : "white",
              }}
            >
              Staff level:
            </Label>
            <Stack.Item grow={1} shrink={1}>
              <Dropdown
                options={staffLevelOptions}
                selectedKey={selectedStaffLevel || "mod"}
                onChange={(_, item) =>
                  setSelectedStaffLevel((item?.key as string) || "mod")
                }
                style={{ minWidth: "200px" }}
              />
            </Stack.Item>
          </Stack>

          {/* Options */}
          <Stack
            horizontal
            style={{ width: "100%", paddingLeft: "8px" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Checkbox
              label="First feature on page"
              checked={isFirstFeature}
              onChange={(_, newValue) => setIsFirstFeature(!!newValue)}
              styles={{
                checkbox: { borderColor: "white !important" },
                checkmark: { color: "white !important" },
                text: { color: "white !important" },
              }}
            />
            <Checkbox
              label="Community tag"
              checked={isCommunityTag}
              onChange={(_, newValue) => setIsCommunityTag(!!newValue)}
              styles={{
                checkbox: { borderColor: "white !important" },
                checkmark: { color: "white !important" },
                text: { color: "white !important" },
              }}
            />
          </Stack>

          <Separator />

          {/* Feature script editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                color: "white",
              }}
            >
              Feature script:
            </Label>
            <CommandButton
              iconProps={{ iconName: "Copy" }}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(featureScript)}
              disabled={!featureScript}
              styles={{
                label: { color: "white" },
                labelHovered: { color: "cornflowerblue" },
                labelDisabled: { color: "#606060" },
                iconDisabled: { color: "#606060" },
              }}
            />
          </Stack>
          <TextField
            multiline
            rows={12}
            value={featureScript}
            onChange={(_, newValue) => setFeatureScript(newValue || "")}
          />

          <Separator />

          {/* Comment script editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                color: "white",
              }}
            >
              Comment script:
            </Label>
            <CommandButton
              iconProps={{ iconName: "Copy" }}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(commentScript)}
              disabled={!commentScript}
              styles={{
                label: { color: "white" },
                labelHovered: { color: "cornflowerblue" },
                labelDisabled: { color: "#606060" },
                iconDisabled: { color: "#606060" },
              }}
            />
          </Stack>
          <TextField
            multiline
            rows={6}
            value={commentScript}
            onChange={(_, newValue) => setCommentScript(newValue || "")}
          />

          <Separator />

          {/* Original post script editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                color: "white",
              }}
            >
              Original post script:
            </Label>
            <CommandButton
              iconProps={{ iconName: "Copy" }}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(originalPostScript)}
              disabled={!originalPostScript}
              styles={{
                label: { color: "white" },
                labelHovered: { color: "cornflowerblue" },
                labelDisabled: { color: "#606060" },
                iconDisabled: { color: "#606060" },
              }}
            />
          </Stack>
          <TextField
            multiline
            rows={3}
            value={originalPostScript}
            onChange={(_, newValue) => setOriginalPostScript(newValue || "")}
          />

          <Separator />

          {/* New membership level script editor */}
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Label
              style={{
                width: "auto",
                margin: "4px 8px",
                textAlign: "left",
                whiteSpace: "nowrap",
                color: "white",
              }}
            >
              New membership:
            </Label>
          </Stack>
          <Stack
            horizontal
            style={{ width: "100%" }}
            tokens={{ childrenGap: "8px" }}
          >
            <Dropdown
              options={newLevelOptions}
              selectedKey={selectedNewLevel || "none"}
              onChange={(_, item) =>
                setSelectedNewLevel((item?.key as string) || "mod")
              }
              style={{ width: "200px" }}
            />
            <CommandButton
              iconProps={{ iconName: "Copy" }}
              text="Copy"
              onClick={async () => await navigator.clipboard.writeText(newLevelScript)}
              disabled={!newLevelScript}
              styles={{
                label: { color: "white" },
                labelHovered: { color: "cornflowerblue" },
                labelDisabled: { color: "#606060" },
                iconDisabled: { color: "#606060" },
              }}
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
