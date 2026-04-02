
function Component() {
    if (installer.isInstaller() && systemInfo.productType === "windows") {
        component.loaded.connect(this, Component.prototype.installerLoaded);
    }
    installer.installationFinished.connect(this, Component.prototype.installationFinished);
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


Component.prototype.installationFinished = function()
{

    try{
        var extra = installer.value("ExtraInstanceName");
        if (extra == null)
            extra = "";
        extra = String(extra).replace(/^\s+|\s+$/g, "");
        if (extra.length === 0)
            return;

        var target = installer.value("TargetDir");
        var parentPath = target.replace(/[\/\\][^\/\\]+$/, "");
        console.log("parentPath = "+ parentPath);
        if (parentPath.length === 0)
            return;

        var sep = ifwPathSep();
        // Avoid paths like "D:\\Foo" when parentPath already ends with "\".
        var normalizedParent = String(parentPath);
        while (normalizedParent.length > 0 &&
               normalizedParent.charAt(normalizedParent.length - 1) === sep &&
               normalizedParent.length > 3 /* keep "D:\" */) {
            normalizedParent = normalizedParent.substring(0, normalizedParent.length - 1);
        }

        // Trim trailing separators from target as well (except drive root).
        var normalizedTarget = String(target);
        while (normalizedTarget.length > 0 &&
               normalizedTarget.charAt(normalizedTarget.length - 1) === sep &&
               normalizedTarget.length > 3 /* keep "D:\" */) {
            normalizedTarget = normalizedTarget.substring(0, normalizedTarget.length - 1);
        }

        var dest = (normalizedParent.charAt(normalizedParent.length - 1) === sep)
                ? (normalizedParent + extra)
                : (normalizedParent + sep + extra);

        // IFW will fail CopyDirectory if either side resolves to a drive root like "D:\".
        var driveRootRe = /^[A-Za-z]:\\$/;
        if (driveRootRe.test(normalizedTarget) || driveRootRe.test(dest)) {
            console.log("Skipping CopyDirectory due to drive-root path. source=" + normalizedTarget + " dest=" + dest);
            return;
        }

        console.log("CopyDirectory source=" + normalizedTarget + " dest=" + dest);
        installer.performOperation("CopyDirectory",[normalizedTarget,dest])
    }
    catch (e) {
        print(e);
        console.log("Error in osCopyDirectory: ");
    }
}

Component.prototype.createOperations = function()
{
    try {
        component.createOperations();

        // -------- Windows --------
        if (systemInfo.productType === "windows") {
            component.addOperation("CreateShortcut",
                                   "@TargetDir@/TestProj.exe",// target
                                   "@DesktopDir@/TestProj.lnk",// link-path
                                   "workingDirectory=@TargetDir@",// working-dir
                                   "iconPath=@TargetDir@/TestProj.exe", "iconId=0",// icon
                                   "description=Start App");// description
            console.log("Windows ");
        }

        // -------- Linux / Raspberry Pi (.desktop) --------
        if (systemInfo.productType === "linux") {

            component.addOperation(
                          "CreateDesktopEntry",
                          "TestProj.desktop",
                          "Type=Application",
                          "Name=TestProj",
                          "Exec=@TargetDir@/TestProj",
                          "Icon=@TargetDir@/icon.png",
                          "Terminal=false",
                          "Categories=Utility;"
                          );
        }

    }
    catch (e) {
        print(e);
    }
}
