

function Controller()
{
    installer.uninstallationStarted.connect(this, Controller.prototype.onUninstallationStarted);

}

Controller.prototype.onUninstallationStarted = function()
{
    console.log("In controller onUninstallationStarted.");

    try
    {
        if (installer.isUninstaller())
        {
            var root = installer.value("TargetDir");
            if (!root)
                root = installer.value("InstallDir");
            if (!root)
                root = installer.value("ProductDir");

            if (!root) {
                console.log("No root dir found!");
                return;
            }

            // Go one directory up
            var parentDir = root.replace(/[\/\\][^\/\\]+$/, "");
            console.log("parentDir: " + parentDir);

            var exePath = parentDir + "/default/TestProj";

            console.log("Running: " + exePath + " -u");

            // Make sure executable permission exists
            //installer.execute("chmod", ["+x", exePath]);

            // Execute your app with -u
            var result = installer.execute(exePath, ["-u"]);

            console.log("Result: " + result);
        }
    }
    catch (e)
    {
        console.log("Error: " + e);
    }
}
