import React from "react";
import "./App.css";
import {
    Button,
    Display,
    DrawerBody,
    DrawerHeader,
    DrawerHeaderTitle,
    Image,
    InlineDrawer,
    Title1,
    Title3,
    makeStyles,
    shorthands,
    teamsDarkTheme,
} from "@fluentui/react-components";
import { Dismiss24Regular, PanelLeftExpand24Regular } from "@fluentui/react-icons";
import General from "./General";
import { applicationName, macReleaseNotesLocation, versionLocation } from "./config";
import ReleaseNotes from "./ReleaseNotes";
import { BrowserRouter as Router, Route, Routes, Link } from "react-router-dom";

const useStyles = makeStyles({
    cleanLink: {
        ...shorthands.textDecoration("none"),
        color: "CornflowerBlue",
        "&:hover": {
            ...shorthands.textDecoration("underline"),
            color: "LightBlue",
        },
    },
});

function App() {
    const [open, setOpen] = React.useState(true);

    const styles = useStyles();

    React.useEffect(() => {
        document.title = applicationName + " portal";
    }, []);

    return (
        <div className="App">
            <Router basename={"/app/veroscripts"}>
                <InlineDrawer open={open} position="start">
                    <DrawerHeader style={{ backgroundColor: teamsDarkTheme.colorBrandBackground }}>
                        <DrawerHeaderTitle
                            action={
                                <Button
                                    appearance="subtle"
                                    aria-label="Close"
                                    icon={<Dismiss24Regular />}
                                    onClick={() => setOpen(false)}
                                />
                            }
                        >
                            <div style={{ marginTop: "40px", marginBottom: "40px" }}>
                                <Title1>Information</Title1>
                            </div>
                        </DrawerHeaderTitle>
                    </DrawerHeader>
                    <DrawerBody style={{ marginTop: "40px"}}>
                        <nav>
                            {/* TODO : work on this some day:
                            <Link className={styles.cleanLink} style={{ fontSize: "20pt", marginTop: "40px" }} to="/">
                                About
                            </Link>
                            */}
                            <div style={{ display: "flex", flexDirection: "column" }}>
                                <Title3>macOS</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/macOS">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/macReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                            <div style={{ display: "flex", flexDirection: "column", marginTop: "40px" }}>
                                <Title3>Windows</Title3>
                                <div style={{ marginLeft: "20px", display: "flex", flexDirection: "column" }}>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 8px 0" }} to="/windows">
                                        Install
                                    </Link>
                                    <Link className={styles.cleanLink} style={{ fontSize: "15pt", margin: "8px 0 0 0" }} to="/windowsReleaseNotes">
                                        Release notes
                                    </Link>
                                </div>
                            </div>
                        </nav>
                    </DrawerBody>
                </InlineDrawer>
                {open ? (
                    <></>
                ) : (
                    <Button
                        appearance="subtle"
                        aria-label="Open"
                        icon={<PanelLeftExpand24Regular />}
                        onClick={() => setOpen(true)}
                    />
                )}
                <div
                    style={{
                        display: "flex",
                        flexDirection: "column",
                        width: "100%",
                        padding: "20px",
                        backgroundColor: teamsDarkTheme.colorNeutralBackground3,
                    }}
                >
                    <div style={{ display: "flex", flexDirection: "row", width: "100%" }}>
                        <Image alt="Application Icon" src="./AppIcon.png" width={128} height={128} style={{ marginRight: "20px" }} />
                        <Display>{applicationName}</Display>
                    </div>
                    <div
                        style={{
                            width: "calc(100% - 40px)",
                            height: "100%",
                            margin: "20px",
                            overflow: "auto",
                            backgroundColor: teamsDarkTheme.colorNeutralBackground4,
                            borderRadius: "8px",
                        }}
                    >
                        <Routes>
                            <Route path="/" element={(
                                <div style={{ marginTop: "200px", textAlign: "center" }}>
                                    <Title3 style={{opacity: "0.3"}}>&lt;- &nbsp;select a link for more information</Title3>
                                </div>
                            )} />
                            <Route path="/macOS" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="macOS"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/macReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="macOS"
                                    location={macReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                            <Route path="/windows" element={(
                                <General
                                    applicationName={applicationName}
                                    platform="windows"
                                    versionLocation={versionLocation} />
                            )} />
                            <Route path="/windowsReleaseNotes" element={(
                                <ReleaseNotes
                                    applicationName={applicationName}
                                    platform="windows"
                                    location={macReleaseNotesLocation}
                                    versionLocation={versionLocation}
                                />
                            )} />
                        </Routes>
                    </div>
                </div>
            </Router>
        </div>
    );
}

export default App;
