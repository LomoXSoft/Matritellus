// The installer of Matritellus, and (compiled with /define:UNINSTALL) its uninstaller.
//
// It is built by tools/make_installer.py with the C# compiler that comes with Windows (.NET Framework 4), so nothing
// has to be downloaded to make it, and it runs on any Windows 10 or 11 as it is. The game travels inside it as a zip
// (the resource "payload.zip"). It installs for the current user only: no administrator rights, nothing outside the
// user's own folders and their own branch of the registry.
//
//   <folder chosen>\Matritellus.exe, Matritellus.pck, Matritellus.ico, radio\..., Desinstalar.exe
//   shortcuts in the Start menu and (if ticked) on the desktop
//   an entry in "Apps" so that it can be removed from Windows' own list
//   _userdata\... in the zip goes to %APPDATA%\Godot\app_userdata\Matritellus, only where there is nothing yet
//
// Saved games and settings live in that last folder and the uninstaller leaves them alone.
using System;
using System.ComponentModel;
using System.Diagnostics;
using System.Drawing;
using System.IO;
using System.IO.Compression;
using System.Reflection;
using System.Windows.Forms;
using Microsoft.Win32;

static class Where
{
    public const string NAME = "Matritellus";
    public const string KEY = @"Software\Microsoft\Windows\CurrentVersion\Uninstall\Matritellus";

    public static string Desktop() { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.DesktopDirectory), NAME + ".lnk"); }
    public static string Menu() { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.Programs), NAME + ".lnk"); }
    public static string UserData() { return Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.ApplicationData), @"Godot\app_userdata\" + NAME); }
}

#if UNINSTALL

static class Program
{
    [STAThread]
    static void Main(string[] args)
    {
        Application.EnableVisualStyles();
        bool silent = args.Length > 0 && args[0].Equals("/silent", StringComparison.OrdinalIgnoreCase);     // (no questions, no windows)
        string dir = Path.GetDirectoryName(Assembly.GetExecutingAssembly().Location);
        if (!File.Exists(Path.Combine(dir, "Matritellus.pck")))
        {
            if (!silent) MessageBox.Show("Aquí no está el juego. No toco na.", "Desinstalar Matritellus", MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        DialogResult yes = silent ? DialogResult.Yes : MessageBox.Show("¿Quitamos Matritellus de este ordenador?\n\nLas partidas guardadas no se tocan.", "Desinstalar Matritellus",
            MessageBoxButtons.YesNo, MessageBoxIcon.Question);
        if (yes != DialogResult.Yes)
            return;
        try
        {
            // only what the installer put there, by name: never the whole folder, whatever it is
            foreach (string name in new string[] { "Matritellus.exe", "Matritellus.pck", "Matritellus.ico" })
                if (File.Exists(Path.Combine(dir, name)))
                    File.Delete(Path.Combine(dir, name));
            if (Directory.Exists(Path.Combine(dir, "radio")))
                Directory.Delete(Path.Combine(dir, "radio"), true);
            foreach (string link in new string[] { Where.Desktop(), Where.Menu() })
                if (File.Exists(link))
                    File.Delete(link);
            Registry.CurrentUser.DeleteSubKeyTree(Where.KEY, false);
        }
        catch (Exception e)
        {
            if (!silent) MessageBox.Show("No se ha podido quitar todo (¿está el juego abierto?).\n\n" + e.Message, "Desinstalar Matritellus", MessageBoxButtons.OK, MessageBoxIcon.Error);
            return;
        }
        if (!silent) MessageBox.Show("Quitao. Las partidas guardadas siguen en\n" + Where.UserData(), "Desinstalar Matritellus", MessageBoxButtons.OK, MessageBoxIcon.Information);
        // this program cannot delete itself while it runs: a moment after it closes, it goes, and the folder if it is left empty
        string me = Assembly.GetExecutingAssembly().Location;
        ProcessStartInfo later = new ProcessStartInfo("cmd.exe", "/c ping -n 3 127.0.0.1 >nul & del \"" + me + "\" & rmdir \"" + dir + "\"");
        later.CreateNoWindow = true;
        later.UseShellExecute = false;
        later.WorkingDirectory = Path.GetTempPath();
        Process.Start(later);
    }
}

#else

class Setup : Form
{
    static readonly Color WALL = Color.FromArgb(246, 240, 226);      // the whitewash of the game's menus
    static readonly Color INK = Color.FromArgb(58, 38, 26);
    static readonly Color TERRA = Color.FromArgb(176, 69, 42);
    static readonly Color INDIGO = Color.FromArgb(30, 69, 168);

    TextBox where;
    CheckBox desktop;
    Button go, browse, close;
    ProgressBar bar;
    Label status;
    BackgroundWorker work;
    string dir = "";
    bool done = false;

    public Setup()
    {
        Text = "Instalar Matritellus";
        ClientSize = new Size(560, 372);
        FormBorderStyle = FormBorderStyle.FixedDialog;
        MaximizeBox = false;
        StartPosition = FormStartPosition.CenterScreen;
        BackColor = WALL;
        Font = new Font("Segoe UI", 10f);
        Icon = Icon.ExtractAssociatedIcon(Assembly.GetExecutingAssembly().Location);

        Panel band = new Panel();                                  // the indigo skirting of a Manchego wall, along the bottom
        band.BackColor = INDIGO;
        band.SetBounds(0, 372 - 14, 560, 14);
        Controls.Add(band);

        PictureBox crest = new PictureBox();
        crest.SetBounds(24, 22, 132, 132);
        crest.SizeMode = PictureBoxSizeMode.Zoom;
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("logo.png"))
            if (s != null)
                crest.Image = Image.FromStream(s);
        Controls.Add(crest);

        Label title = new Label();
        title.Text = "Matritellus";
        title.Font = new Font("Georgia", 26f, FontStyle.Bold);
        title.ForeColor = TERRA;
        title.SetBounds(172, 26, 370, 48);
        Controls.Add(title);

        Label blurb = new Label();
        blurb.Text = "Versión de prueba (" + Version() + ").\nSe instala solo para ti, sin permisos de administrador. Ocupa unos " + Megas() + " MB.";
        blurb.ForeColor = INK;
        blurb.SetBounds(174, 80, 368, 74);
        Controls.Add(blurb);

        Label l = new Label();
        l.Text = "¿Dónde lo ponemos?";
        l.ForeColor = INK;
        l.SetBounds(24, 172, 300, 22);
        Controls.Add(l);

        where = new TextBox();
        where.Text = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), @"Programs\Matritellus");
        where.SetBounds(24, 196, 410, 26);
        Controls.Add(where);

        browse = new Button();
        browse.Text = "Cambiar…";
        browse.SetBounds(442, 194, 94, 30);
        browse.Click += delegate { Browse(); };
        Controls.Add(browse);

        desktop = new CheckBox();
        desktop.Text = "Acceso directo en el escritorio";
        desktop.Checked = true;
        desktop.ForeColor = INK;
        desktop.SetBounds(24, 232, 400, 24);
        Controls.Add(desktop);

        bar = new ProgressBar();
        bar.SetBounds(24, 268, 512, 16);
        bar.Visible = false;
        Controls.Add(bar);

        status = new Label();
        status.ForeColor = INK;
        status.SetBounds(24, 288, 512, 22);
        Controls.Add(status);

        go = new Button();
        go.Text = "Enga, instalar";
        go.Font = new Font("Segoe UI", 11f, FontStyle.Bold);
        go.SetBounds(376, 312, 160, 36);
        go.Click += delegate { Go(); };
        Controls.Add(go);
        AcceptButton = go;

        close = new Button();
        close.Text = "Cerrar";
        close.SetBounds(270, 312, 98, 36);
        close.Click += delegate { Close(); };
        Controls.Add(close);

        work = new BackgroundWorker();
        work.WorkerReportsProgress = true;
        work.DoWork += delegate(object o, DoWorkEventArgs e) { Install(dir, (bool)e.Argument, work.ReportProgress); };
        work.ProgressChanged += delegate(object o, ProgressChangedEventArgs e) { bar.Value = Math.Min(1000, e.ProgressPercentage); status.Text = (string)e.UserState; };
        work.RunWorkerCompleted += Finished;
    }

    static string Version()
    {
        Version v = Assembly.GetExecutingAssembly().GetName().Version;
        return v.Major + "." + v.Minor.ToString("00") + "." + v.Build.ToString("00");
    }

    static long Megas()
    {
        long total = 0;
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
        using (ZipArchive zip = new ZipArchive(s, ZipArchiveMode.Read))
            foreach (ZipArchiveEntry e in zip.Entries)
                total += e.Length;
        return total / (1024 * 1024);
    }

    void Browse()
    {
        using (FolderBrowserDialog d = new FolderBrowserDialog())
        {
            d.Description = "El juego irá en una carpeta «Matritellus» dentro de la que elijas.";
            if (d.ShowDialog(this) == DialogResult.OK)
                where.Text = Path.Combine(d.SelectedPath, Where.NAME);
        }
    }

    void Go()
    {
        if (done)                                                  // (the same button, afterwards: play)
        {
            ProcessStartInfo play = new ProcessStartInfo(Path.Combine(dir, "Matritellus.exe"));
            play.WorkingDirectory = dir;
            Process.Start(play);
            Close();
            return;
        }
        try
        {
            dir = Path.GetFullPath(where.Text.Trim());
        }
        catch (Exception)
        {
            MessageBox.Show(this, "Esa carpeta no vale.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        // always a folder of its own: the uninstaller removes it if it is left empty
        if (!String.Equals(Path.GetFileName(dir.TrimEnd('\\')), Where.NAME, StringComparison.OrdinalIgnoreCase))
            dir = Path.Combine(dir, Where.NAME);
        where.Text = dir;
        if (Process.GetProcessesByName("Matritellus").Length > 0)
        {
            MessageBox.Show(this, "El juego está abierto. Ciérralo y dale otra vez.", Text, MessageBoxButtons.OK, MessageBoxIcon.Warning);
            return;
        }
        go.Enabled = false; browse.Enabled = false; where.Enabled = false; desktop.Enabled = false; close.Enabled = false;
        bar.Maximum = 1000;
        bar.Visible = true;
        work.RunWorkerAsync(desktop.Checked);
    }

    /// puts the game in `dir`, with its shortcuts and its entry in Windows' list of programs
    static void Install(string dir, bool on_desktop, Action<int, object> tell)
    {
        Directory.CreateDirectory(dir);
        string root = Path.GetFullPath(dir).TrimEnd('\\') + "\\";
        string data = Where.UserData().TrimEnd('\\') + "\\";
        using (Stream s = Assembly.GetExecutingAssembly().GetManifestResourceStream("payload.zip"))
        using (ZipArchive zip = new ZipArchive(s, ZipArchiveMode.Read))
        {
            long total = 1, sofar = 0;
            foreach (ZipArchiveEntry e in zip.Entries)
                total += e.Length;
            byte[] buf = new byte[1 << 16];
            foreach (ZipArchiveEntry e in zip.Entries)
            {
                if (e.FullName.EndsWith("/"))
                    continue;
                string rel = e.FullName.Replace('/', '\\');
                bool seed = rel.StartsWith("_userdata\\");           // things for the game's own data folder, only if it has none
                string to = Path.GetFullPath(seed ? data + rel.Substring(10) : root + rel);
                if (!to.StartsWith(seed ? data : root, StringComparison.OrdinalIgnoreCase))
                    throw new IOException("Fichero fuera de sitio: " + e.FullName);
                if (seed && File.Exists(to))
                {
                    sofar += e.Length;
                    continue;
                }
                Directory.CreateDirectory(Path.GetDirectoryName(to));
                tell((int)(sofar * 1000 / total), e.Name);
                using (Stream from = e.Open())
                using (FileStream file = new FileStream(to, FileMode.Create, FileAccess.Write))
                {
                    int n;
                    int ticks = 0;
                    while ((n = from.Read(buf, 0, buf.Length)) > 0)
                    {
                        file.Write(buf, 0, n);
                        sofar += n;
                        if (++ticks % 64 == 0)
                            tell((int)(sofar * 1000 / total), e.Name);
                    }
                }
            }
        }
        tell(1000, "Accesos directos…");
        string exe = Path.Combine(dir, "Matritellus.exe");
        string ico = Path.Combine(dir, "Matritellus.ico");
        Shortcut(Where.Menu(), exe, ico);
        if (on_desktop)
            Shortcut(Where.Desktop(), exe, ico);
        long kb = 0;
        foreach (string f in Directory.GetFiles(dir, "*", SearchOption.AllDirectories))
            kb += new FileInfo(f).Length / 1024;
        using (RegistryKey k = Registry.CurrentUser.CreateSubKey(Where.KEY))
        {
            k.SetValue("DisplayName", Where.NAME);
            k.SetValue("DisplayVersion", Version());
            k.SetValue("Publisher", "LomoXGames");
            k.SetValue("InstallLocation", dir);
            k.SetValue("DisplayIcon", ico);
            k.SetValue("UninstallString", "\"" + Path.Combine(dir, "Desinstalar.exe") + "\"");
            k.SetValue("NoModify", 1, RegistryValueKind.DWord);
            k.SetValue("NoRepair", 1, RegistryValueKind.DWord);
            k.SetValue("EstimatedSize", (int)kb, RegistryValueKind.DWord);
        }
    }

    static void Shortcut(string link, string target, string icon)
    {
        Type t = Type.GetTypeFromProgID("WScript.Shell");
        object shell = Activator.CreateInstance(t);
        object s = t.InvokeMember("CreateShortcut", BindingFlags.InvokeMethod, null, shell, new object[] { link });
        Type st = s.GetType();
        st.InvokeMember("TargetPath", BindingFlags.SetProperty, null, s, new object[] { target });
        st.InvokeMember("WorkingDirectory", BindingFlags.SetProperty, null, s, new object[] { Path.GetDirectoryName(target) });
        st.InvokeMember("IconLocation", BindingFlags.SetProperty, null, s, new object[] { icon + ",0" });
        st.InvokeMember("Description", BindingFlags.SetProperty, null, s, new object[] { "Matritellus" });
        st.InvokeMember("Save", BindingFlags.InvokeMethod, null, s, new object[0]);
    }

    void Finished(object sender, RunWorkerCompletedEventArgs e)
    {
        close.Enabled = true;
        if (e.Error != null)
        {
            status.Text = "No ha podido ser.";
            MessageBox.Show(this, "No se ha podido instalar:\n\n" + e.Error.Message, Text, MessageBoxButtons.OK, MessageBoxIcon.Error);
            go.Enabled = true; browse.Enabled = true; where.Enabled = true; desktop.Enabled = true;
            bar.Visible = false;
            return;
        }
        done = true;
        bar.Value = 1000;
        status.Text = "¡Apañao! Ya está instalao.";
        status.ForeColor = TERRA;
        go.Text = "Jugar";
        go.Enabled = true;
    }

    /// With nothing after its name, the window. Otherwise, for whoever installs it from a script:
    ///   /silent            installs without a window (exit code 0 if it went well)
    ///   /dir=<folder>      where (as in the window, the game goes in a folder called Matritellus)
    ///   /nodesktop         no shortcut on the desktop
    ///   /shot=<file.png>   only saves a picture of the window, to see how it looks
    [STAThread]
    static int Main(string[] args)
    {
        Application.EnableVisualStyles();
        Application.SetCompatibleTextRenderingDefault(false);
        bool silent = false, on_desktop = true;
        string to = null, shot = null;
        foreach (string a in args)
        {
            if (a.Equals("/silent", StringComparison.OrdinalIgnoreCase)) silent = true;
            else if (a.Equals("/nodesktop", StringComparison.OrdinalIgnoreCase)) on_desktop = false;
            else if (a.StartsWith("/dir=", StringComparison.OrdinalIgnoreCase)) to = a.Substring(5).Trim('"');
            else if (a.StartsWith("/shot=", StringComparison.OrdinalIgnoreCase)) shot = a.Substring(6).Trim('"');
        }
        Setup form = new Setup();
        if (to != null)
            form.where.Text = to;
        form.desktop.Checked = on_desktop;
        if (shot != null)
        {
            form.Show();
            Application.DoEvents();
            using (Bitmap b = new Bitmap(form.Width, form.Height))
            {
                form.DrawToBitmap(b, new Rectangle(0, 0, form.Width, form.Height));
                b.Save(shot, System.Drawing.Imaging.ImageFormat.Png);
            }
            return 0;
        }
        if (silent)
        {
            try
            {
                string dir = Path.GetFullPath(form.where.Text.Trim());
                if (!String.Equals(Path.GetFileName(dir.TrimEnd('\\')), Where.NAME, StringComparison.OrdinalIgnoreCase))
                    dir = Path.Combine(dir, Where.NAME);
                Install(dir, on_desktop, delegate(int n, object what) { });
                return 0;
            }
            catch (Exception)
            {
                return 1;
            }
        }
        Application.Run(form);
        return 0;
    }
}

#endif
