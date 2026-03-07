# Smart Academic Project Hub – Setup for Beginners

You don't need to know how to code. Follow these steps in order.

---

## What you need on your PC

1. **SQL Server** – the database (where data is stored).
2. **.NET** – to run the API (already used when we created the project).
3. **Flutter** – to run the app (already used when we created the project).

If you're not sure whether SQL Server is installed, try **Step 1** below. If the script says "cannot connect", then you need to install SQL Server (see **Appendix A**).

---

## Step 1: Create the database (no SSMS needed)

We'll run the database script from the command line so you don't have to use SSMS.

1. Press **Windows key**, type **PowerShell**, click **Windows PowerShell** (or **Terminal**).
2. Copy and paste this **whole block** (one line at a time is fine), then press Enter after the last line:

```powershell
cd d:\SmartAcademicProjectHub
sqlcmd -S localhost -E -i "Database\Schema.sql"
```

- If it runs and prints "Schema created successfully" (or similar), **Step 1 is done.** Go to **Step 2**.
- If you see an error like **"sqlcmd is not recognized"** or **"cannot connect"**:
  - **"sqlcmd is not recognized"** → SQL Server tools might not be in your PATH. Try this instead (use your own Server name if you know it, e.g. `localhost\SQLEXPRESS`):

```powershell
cd d:\SmartAcademicProjectHub
& "C:\Program Files\Microsoft SQL Server\Client SDK\ODBC\170\Tools\Binn\SQLCMD.EXE" -S localhost -E -i "Database\Schema.sql"
```

  - **"cannot connect" / "Login failed"** → SQL Server might not be installed or not running. See **Appendix A** to install SQL Server Express.

---

## Step 2: Run the API (backend)

1. Open **PowerShell** or **Terminal** again.
2. Run these two commands, one after the other:

```powershell
cd d:\SmartAcademicProjectHub\Api
dotnet run
```

3. Leave this window **open**. You should see something like: **"Now listening on: http://localhost:5264"**.
4. Open your **browser** and go to:  
   **http://localhost:5264/api/universities**  
   You should see a bit of text in square brackets `[{ ... }, { ... }]`. That means the API is working.

---

## Step 3: Run the app (Flutter)

1. Open a **new** PowerShell/Terminal window (keep the API window open).
2. Run these commands, one after the other:

```powershell
cd d:\SmartAcademicProjectHub\app
flutter pub get
flutter run
```

3. When Flutter asks you to **choose a device**, pick:
   - **Chrome** (to run in the browser), or  
   - **Windows** (to run as a desktop app), or  
   - Your phone/emulator if you have one.
4. The app will open. You should see a **login screen**.
5. Click **Register**, choose a university, enter your name, email, and a password (at least 6 characters), then click **Create account**. You should then see the **dashboard**.

---

## Summary

| Step | What to do | How you know it worked |
|------|------------|-------------------------|
| 1 | Run the `sqlcmd` command above from `d:\SmartAcademicProjectHub` | No error, or "Schema created successfully" |
| 2 | In `Api` folder run `dotnet run` | "Now listening on..." and browser shows text at `/api/universities` |
| 3 | In `app` folder run `flutter pub get` then `flutter run` | App opens; you can Register and see the dashboard |

---

## Appendix A: Install SQL Server Express (if you don't have it)

1. Open your browser and go to:  
   **https://www.microsoft.com/en-us/sql-server/sql-server-downloads**
2. Scroll to **Express** and click **Download**.
3. Run the installer. When it asks, choose **Basic** installation.
4. When it finishes, **restart** your PC if it asks.
5. Then try **Step 1** again with:

```powershell
sqlcmd -S localhost\SQLEXPRESS -E -i "d:\SmartAcademicProjectHub\Database\Schema.sql"
```

If it still doesn't work, the connection string in the API might need the same server name. In that case, open `d:\SmartAcademicProjectHub\Api\appsettings.json` and change the line that says `"Server=localhost;` to:

`"Server=localhost\\SQLEXPRESS;`

(save the file, then run **Step 2** again).

---

## Appendix B: What is SSMS?

**SSMS** = **SQL Server Management Studio**. It's a program where you can see tables and data. You **don't need it** to run this project if you use the **sqlcmd** command in Step 1. SSMS is optional and only useful if someone later wants to look at or edit the database by hand.
