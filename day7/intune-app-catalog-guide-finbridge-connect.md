Title: Adding a Windows App to the Intune App Catalog
Date: 2026-08-11
Author: DWP Engineering
Status: Draft

# Adding a Windows App to the Intune App Catalog

Worked example: FinBridge Connect v3.1, packaged as a Windows LOB app in a .intunewin file.

Use this guide when you need to publish a new Windows application to Intune before any phased rollout begins. Do not assign it to the full estate until the pilot group has validated install, detection, and user experience.

## 1) Add the app in Intune

1. Sign in to the Intune admin center.
   - Expected result: You can see the Intune home page and manage apps.

2. Go to the app creation path in your tenant.
   - Common path: Intune admin center > Apps > All apps > Add.
   - Some tenants show a slightly different path such as Intune admin center > Apps > Windows > Add.
   - UI drift flag: Verify the live labels in your tenant before proceeding, because Intune menu names and the first landing page change between portal versions.

3. Choose the app type that matches the package.
   - For a Windows LOB app packaged as .intunewin, choose Windows app (Win32) or Win32 app if that is the label your tenant shows.
   - For a Microsoft Store app, choose Microsoft Store app or Microsoft Store app (new), depending on the tenant UI.
   - For a simple URL shortcut, choose Web link.
   - Expected result: You are in the correct app type wizard before upload or configuration starts.

4. For the worked example, select the Windows app (Win32) path and upload the FinBridge Connect v3.1 .intunewin package.
   - Expected result: Intune accepts the upload and opens the Win32 app configuration pages.

## 2) Fill in the required fields for a Windows LOB app

1. Complete App information.
   - Name: FinBridge Connect v3.1.
   - Description: Short business description and pilot context, for example FinBridge line-of-business application for finance users.
   - Publisher: FinBridge.
   - Version: 3.1.
   - Expected result: The app name and metadata are clear enough for the pilot group and service desk to identify the package in Intune and in Company Portal.

2. Complete Program.
   - Install command: FinBridgeConnect_Setup.exe /silent.
   - Uninstall command: FinBridgeConnect_Setup.exe /uninstall /silent.
   - Install behavior: Choose System when the app must install for the device and all users, or choose User only when the installer is user-scoped and must run in the user context.
   - For this worked example, use System unless the FinBridge package owner confirms the app is strictly per-user.
   - Expected result: Intune knows how to run the installer and how to remove it later.

3. Complete Requirements.
   - OS architecture: Select the architecture that the installer actually supports. Do not guess; confirm the FinBridge package requirements first.
   - Minimum OS version: Enter the lowest Windows version/build that the app supports.
   - Expected result: Devices that cannot run the app are filtered out before installation starts.

4. Complete Detection rules.
   - Use a registry-based detection rule for the worked example.
   - Registry path: HKLM\SOFTWARE\FinBridge\Connect.
   - Value name: Version.
   - Detection logic: Equals 3.1.
   - If the app writes to a different registry view on 64-bit Windows, match the correct view used by the installer.
   - Expected result: Intune can tell that the app installed successfully without relying only on the installer exit code.

5. Complete Return codes.
   - 0: Success.
   - 3010: Success, soft reboot required.
   - 1641: Success, reboot initiated by installer.
   - 1618: Retry.
   - All other codes: Treat as failure unless your packaging standard explicitly maps them differently.
   - Expected result: Intune classifies common installer outcomes correctly instead of marking a successful install as failed.

6. Review the summary page before saving.
   - Expected result: The app type is Windows app (Win32), the commands are correct, the detection rule matches the registry version check, and the return codes match your deployment standard.

## 3) Assign the app safely

1. Understand the assignment types before you target any group.
   - Required: Intune installs the app automatically on assigned devices or users.
   - Available: Users can install the app themselves from Company Portal.
   - Uninstall: Intune removes the app from the assigned scope.
   - UI drift flag: Some tenants label these slightly differently, for example Available for enrolled devices; verify the live label in your tenant.
   - Expected result: You know whether the app is being pushed, offered, or removed.

2. Assign the new app to a small pilot group first.
   - Use a limited test group of known devices and users.
   - Do not assign a new app straight to the full 10,000-device fleet.
   - Reason: The pilot group surfaces install failures, detection mistakes, OS-architecture mismatches, and reboot problems before those issues affect the whole estate.
   - Expected result: Any packaging or deployment defect is contained to a small blast radius.

3. Keep broader rollout blocked until the pilot is stable.
   - Required checks before expansion: install completes, detection passes, and the help desk reports no repeatable user-impact issue.
   - Expected result: You have evidence to justify moving from pilot to wider deployment.

## 4) Verify the app and installation status

1. Confirm the app appears correctly in the catalog.
   - Open Intune admin center > Apps > All apps.
   - Select FinBridge Connect v3.1.
   - Check that the app type, publisher, version, commands, and detection rule match what you intended to publish.
   - If you used Available assignment, confirm the app also appears in Company Portal for the pilot user.
   - Expected result: The catalog entry looks correct before you widen the rollout.

2. Check install status on an assigned test device.
   - Open Intune admin center > Devices > All devices.
   - Select the pilot device.
   - Open the device app or managed apps status view in your tenant.
   - UI drift flag: This status page can appear under different labels, such as Managed apps, Device install status, or Apps; verify the live page name in your tenant.
   - Expected result: You can see the deployment state for FinBridge Connect v3.1 on the test device.

3. Interpret the common status values.
   - Installed: The app installed and the detection rule passed.
   - Failed: The install command failed, the uninstall or install logic returned an error, or the detection rule did not confirm success.
   - Not applicable: The device is out of scope because it does not meet requirements, does not match the assignment, or cannot receive the app.
   - Expected result: You can tell the difference between a real install failure and a device that simply was not eligible.

4. Confirm the result on the device itself if the portal result is unclear.
   - Open Company Portal on the pilot device if the app was assigned as Available, or check the installed program locally if it was Required.
   - Verify that FinBridge Connect opens and that the registry value HKLM\SOFTWARE\FinBridge\Connect\Version is 3.1.
   - Expected result: The device and Intune agree that the app is present.

5. Only widen the assignment after pilot verification passes.
   - Expected result: The app is ready for the next rollout phase, and the initial pilot has proven the package, detection, and assignment path.
