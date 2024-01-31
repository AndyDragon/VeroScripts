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
  PrimaryButton,
  Separator,
  Stack,
  Text,
  TextField,
} from "@fluentui/react";
import { useBoolean } from '@fluentui/react-hooks';
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

const modalPropsStyles = { main: { maxWidth: 450 } };

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
  const [hideDialog, { toggle: toggleHideDialog }] = useBoolean(true);
  const [placeholders, setPlaceholders] = useState<Record<string, string>>({});
  const pages = useRef<Pages>();
  const scriptWithPlaceholders = useRef<string>("");
  const scriptWithPlaceholdersUntouched = useRef<string>("");

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
    setPlaceholders({});
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

  function checkForPlaceholders(scripts: string[], forceEdit?: boolean) {
    const placeholdersFound: string[] = [];
    scripts.forEach(script => {
      const matches = script.matchAll(/\[\[([^\]]*)\]\]/g);
      [...matches].forEach(match => {
        placeholdersFound.push(match[1]);
      });
    });
    if (placeholdersFound.length) {
      let needEditor = false;
      placeholdersFound.forEach(placeholderFound => {
        if (!Object.keys(placeholders).includes(placeholderFound)) {
          needEditor = true;
          placeholders[placeholderFound] = "";
        }
      });
      if (needEditor || forceEdit) {
        toggleHideDialog();
        return true;
      }
    }
    return false;
  }

  async function copyScript(script: string, additionalScripts: string[], forceEdit?: boolean) {
    scriptWithPlaceholders.current = script;
    scriptWithPlaceholdersUntouched.current = script;
    Object.keys(placeholders).forEach(placeholder => {
      const placeholderRegEx = new RegExp("\\[\\[" + placeholder + "\\]\\]", "g");
      scriptWithPlaceholders.current = scriptWithPlaceholders.current.replaceAll(placeholderRegEx, placeholders[placeholder]);
    });
    if (!checkForPlaceholders([scriptWithPlaceholders.current, ...additionalScripts], forceEdit)) {
      await navigator.clipboard.writeText(scriptWithPlaceholders.current);
    }
  }

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
    <>
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
                onClick={async () => {
                  await copyScript(featureScript, [commentScript, originalPostScript]);
                }}
                disabled={!featureScript}
                styles={{
                  label: { color: "white" },
                  labelHovered: { color: "cornflowerblue" },
                  labelDisabled: { color: "#606060" },
                  iconDisabled: { color: "#606060" },
                }}
              />
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy (edit placeholders)"
                onClick={async () => {
                  await copyScript(featureScript, [commentScript, originalPostScript], true);
                }}
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
                onClick={async () => {
                  await copyScript(commentScript, [featureScript, originalPostScript]);
                }}
                disabled={!commentScript}
                styles={{
                  label: { color: "white" },
                  labelHovered: { color: "cornflowerblue" },
                  labelDisabled: { color: "#606060" },
                  iconDisabled: { color: "#606060" },
                }}
              />
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy (edit placeholders)"
                onClick={async () => {
                  await copyScript(commentScript, [featureScript, originalPostScript], true);
                }}
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
                onClick={async () => {
                  await copyScript(originalPostScript, [featureScript, commentScript]);
                }}
                disabled={!originalPostScript}
                styles={{
                  label: { color: "white" },
                  labelHovered: { color: "cornflowerblue" },
                  labelDisabled: { color: "#606060" },
                  iconDisabled: { color: "#606060" },
                }}
              />
              <CommandButton
                iconProps={{ iconName: "Copy" }}
                text="Copy (edit placeholders)"
                onClick={async () => {
                  await copyScript(originalPostScript, [featureScript, commentScript], true);
                }}
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
        {
          Object.keys(placeholders).map(key => (
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
          ))
        }
        <hr/>
        <DialogFooter>
          <PrimaryButton onClick={async () => {
            let scriptToCopy = scriptWithPlaceholdersUntouched.current;
            Object.keys(placeholders).forEach(placeholder => {
              const placeholderRegEx = new RegExp("\\[\\[" + placeholder + "\\]\\]", "g");
              scriptToCopy = scriptToCopy.replaceAll(placeholderRegEx, placeholders[placeholder]);
            });
            await navigator.clipboard.writeText(scriptToCopy);
            toggleHideDialog();
          }} text="Copy" />
          <DefaultButton onClick={async () => {
            await navigator.clipboard.writeText(scriptWithPlaceholdersUntouched.current);
            toggleHideDialog();
          }} text="Copy with placeholders" />
        </DialogFooter>
      </Dialog>
    </>
  );
}

export default App;
