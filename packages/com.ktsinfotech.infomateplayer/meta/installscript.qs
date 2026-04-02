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

    return parent.replace(/\//g, systemInfo.pathSeparator);
}

Component.prototype.createOperations = function() {
    component.createOperations();

    var redist = "@TargetDir@\\ThirdParty\\VC_redist.x64.exe";
    if (installer.fileExists(redist)) {
        component.addOperation("Execute", redist, "/install /quiet /norestart");
    }

    var settingsExe = "@TargetDir@\\InfomateSettings.exe";
    if (installer.fileExists(settingsExe)) {
        component.addOperation("CreateShortcut",
            settingsExe,
            "@StartMenuDir@\\Infomate Settings.lnk",
            "workingDirectory=@TargetDir@");

        component.addOperation("CreateShortcut",
            settingsExe,
            "@DesktopDir@\\Infomate Settings.lnk",
            "workingDirectory=@TargetDir@");
    }

    var extra = installer.value("ExtraInstanceName");
    if (extra == null)
        extra = "";
    extra = String(extra).replace(/^\s+|\s+$/g, "");
    if (extra.length === 0)
        return;

    var target = installer.value("TargetDir");
    var parentPath = parentFolder(target);
    if (parentPath.length === 0)
        return;

    var sep = systemInfo.pathSeparator;
    var dest = parentPath + sep + extra;

    component.addOperation("CopyDirectory", target, dest);
}
