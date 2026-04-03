
function Component() {
    if (installer.isInstaller() && systemInfo.productType === "windows") {
        component.loaded.connect(this, Component.prototype.installerLoaded);
    }
}


Component.prototype.installerLoaded = function() {
    // Page after target directory, before component selection (same idea as Inno wpSelectDir page).
    if (installer.addWizardPage(component, "AdditionalInstanceWidget", QInstaller.ComponentSelection)) {
        var widget = gui.pageWidgetByObjectName("DynamicAdditionalInstanceWidget");
        if (widget != null) {
            widget.instanceNameEdit.textChanged.connect(this, Component.prototype.extraInstanceNameChanged);
            installer.setValue("ExtraInstanceName", "");
            widget.complete = true;
        }
    }
}

Component.prototype.extraInstanceNameChanged = function(text) {
    var widget = gui.pageWidgetByObjectName("DynamicAdditionalInstanceWidget");
    if (widget == null)
        return;
    var t = String(text).replace(/^\s+|\s+$/g, "");
    installer.setValue("ExtraInstanceName", t);
    if (t.length === 0) {
        widget.complete = true;
        return;
    }
    if (t.indexOf("\\") >= 0 || t.indexOf("/") >= 0 || t.indexOf(":") >= 0 ||
        t.indexOf("*") >= 0 || t.indexOf("?") >= 0 || t.indexOf("\"") >= 0 ||
        t.indexOf("<") >= 0 || t.indexOf(">") >= 0 || t.indexOf("|") >= 0) {
        widget.complete = false;
        return;
    }
    var target = installer.value("TargetDir");
    var base = lastPathSegment(target);
    if (base.length > 0 && t.toLowerCase() === base.toLowerCase()) {
        widget.complete = false;
        return;
    }
    widget.complete = true;
}

// IFW 4.x sometimes leaves systemInfo.pathSeparator undefined in .qs scripts; never concatenate it raw.
function ifwPathSep() {
    var s = systemInfo.pathSeparator;
    if (s !== undefined && s !== null && String(s).length > 0)
        return String(s);
    return (systemInfo.productType === "windows") ? "\\" : "/";
}

function lastPathSegment(path) {
    var p = path;
    p = p.replace(/\\/g, "/");
    var i = p.lastIndexOf("/");
    if (i < 0)
        return "";
    return p.substring(i + 1);
}

function parentFolder(path) {
    var p = String(path);
    if (p.length === 0)
        return "";

    // Normalize to forward slashes for parsing.
    p = p.replace(/\\/g, "/");

    // Trim trailing slashes (but keep e.g. "C:/").
    while (p.length > 1 && p.charAt(p.length - 1) === "/" && !/^[A-Za-z]:\/$/.test(p)) {
        p = p.substring(0, p.length - 1);
    }

    var i = p.lastIndexOf("/");
    if (i < 0)
        return "";

    var parent = p.substring(0, i);

    // If we ended up with "C:", normalize to "C:/" (drive root).
    if (/^[A-Za-z]:$/.test(parent))
        parent = parent + "/";

    // No parent above drive root.
    if (/^[A-Za-z]:\/$/.test(p))
        return "";

    return parent.replace(/\//g, ifwPathSep());
}

Component.prototype.createOperationsForArchive = function(archive)
{
    try
    {
        var target = installer.value("TargetDir");

        var defaultDir = target + "/default";
        component.addOperation("Extract", archive, defaultDir);

        var extra = installer.value("ExtraInstanceName");
        if (!extra || extra.length === 0)
            return;

        var additionalInstanceDir = target + "/" + extra;
        component.addOperation("Extract", archive, additionalInstanceDir);
    }
    catch (e)
    {
        print("Error in createOperationsForArchive: " + e);
    }
};

function createWinShortcut(folderName, executableName)
{
    component.addOperation("CreateShortcut",
        "@TargetDir@/" + folderName + "/" + executableName+".exe",
        "@DesktopDir@/"+executableName+"_"+folderName+".lnk",
        "workingDirectory=@TargetDir@/" + folderName,
        "iconPath=@TargetDir@/" + folderName + "/" + executableName+".exe",
        "iconId=0",
        "description=Start App"
    );

    print("Windows shortcut created for " + folderName);
}


function createLinuxShortcut(folderName, executableName)
{
    component.addOperation("CreateDesktopEntry",
        executableName+"_" + folderName + ".desktop",
        "Type=Application",
        "Name=TestProj",
        "Exec=@TargetDir@/" + folderName + "/" + executableName,
        "Icon=@TargetDir@/" + folderName + "/" + executableName,
        "Terminal=false",
        "Categories=Utility;"
    );

    print("Linux shortcut created for " + folderName);
}

Component.prototype.createOperations = function()
{
    try
    {
        component.createOperations();

        var executableName = "TestProj";

        // ----- Default instance -----
        if (systemInfo.productType === "windows")
            createWinShortcut("default", executableName);

        if (systemInfo.productType === "opensuse")
            createLinuxShortcut("default", executableName);

        // ----- Extra instance -----
        var extra = installer.value("ExtraInstanceName");
        if (extra && extra.length > 0)
        {
            if (systemInfo.productType === "windows")
                createWinShortcut(extra, executableName);

            if (systemInfo.productType === "opensuse")
                createLinuxShortcut(extra, executableName);
        }
    }
    catch (e)
    {
        print(e);
    }
};
