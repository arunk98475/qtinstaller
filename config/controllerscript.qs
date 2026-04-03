

function Controller()
{
    installer.uninstallationStarted.connect(this, Controller.prototype.onUninstallationStarted);

}

Controller.prototype.onUninstallationStarted = function()
{
    var executableName = "TestProj.exe";
    print("In controller onUninstallationStarted");

    try
    {
        var root = installer.value("TargetDir");
        if (!root)
        {
            print("TargetDir not found");
            return;
        }

        // ---- Run for default instance ----
        var exePath = root + "/default/" + executableName;
        runUninstallCommand(exePath);

        // ---- Run for extra instance if exists ----
        var extra = installer.value("ExtraInstanceName");
        if (extra && extra.length > 0)
        {
            exePath = root + "/" + extra + "/" + executableName;
            runUninstallCommand(exePath);
        }
    }
    catch (e)
    {
        print("Error in onUninstallationStarted: " + e);
    }
};


function runUninstallCommand(exePath)
{
    try
    {
        if (!installer.fileExists(exePath))
        {
            print("Executable not found: " + exePath);
            return;
        }

        // ---- Make executable on Linux ----
        if (systemInfo.productType === "opensuse")
        {
            print("Running chmod +x on: " + exePath);
            installer.execute("chmod", ["+x", exePath]);
        }

        print("Running: " + exePath + " -u");
        var result = installer.execute(exePath, ["-u"]);
        print("Result: " + result);
    }
    catch (e)
    {
        print("Failed to run: " + exePath + " Error: " + e);
    }
}
