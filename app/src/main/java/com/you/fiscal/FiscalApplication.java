package com.you.fiscal;

import me.friwi.jcefmaven.CefAppBuilder;
import org.cef.CefApp;
import org.cef.CefClient;
import org.cef.browser.CefBrowser;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

import javax.swing.*;
import java.awt.*;
import java.io.File;

@SpringBootApplication
public class FiscalApplication {

    static volatile JFrame janela;
    static volatile CefApp cef;
    static volatile CefBrowser navegador;
    static volatile TrayIcon bandeja;

    static void mostrar() {
        SwingUtilities.invokeLater(() -> {
            JFrame f = janela;
            if (f == null) return;
            if (!f.isVisible()) f.setVisible(true);
            if ((f.getExtendedState() & Frame.ICONIFIED) != 0) f.setExtendedState(f.getExtendedState() & ~Frame.ICONIFIED);
            f.setAlwaysOnTop(true);
            f.toFront();
            f.requestFocus();
            f.setAlwaysOnTop(false);
        });
    }

    static void js(String codigo) {
        CefBrowser b = navegador;
        if (b != null) b.executeJavaScript(codigo, "", 0);
    }

    static void esconder(JFrame f) {
        if (bandeja != null) f.setVisible(false);
        else f.setExtendedState(f.getExtendedState() | Frame.ICONIFIED);
    }

    static void criarBandeja(java.util.List<Image> icones) {
        if (!SystemTray.isSupported() || icones.isEmpty()) return;
        try {
            PopupMenu menu = new PopupMenu();
            MenuItem abrir = new MenuItem("Abrir o Fiscal");
            abrir.addActionListener(e -> mostrar());
            MenuItem sair = new MenuItem("Sair do Fiscal");
            sair.addActionListener(e -> encerrar());
            menu.add(abrir);
            menu.addSeparator();
            menu.add(sair);
            TrayIcon t = new TrayIcon(icones.get(Math.min(2, icones.size() - 1)), "Fiscal — You Contabilidade", menu);
            t.setImageAutoSize(true);
            t.addActionListener(e -> mostrar());
            t.addMouseListener(new java.awt.event.MouseAdapter() {
                @Override public void mouseClicked(java.awt.event.MouseEvent e) { if (e.getButton() == java.awt.event.MouseEvent.BUTTON1) mostrar(); }
            });
            SystemTray.getSystemTray().add(t);
            bandeja = t;
        } catch (Exception ignorado) { }
    }

    static void iniciarComWindows() {
        String exe = System.getProperty("fiscal.lancador");
        if (exe == null) return;
        try {
            new ProcessBuilder("reg", "add", "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run", "/v", "Fiscal",
                    "/t", "REG_SZ", "/d", "\"" + exe + "\" --oculto", "/f").redirectErrorStream(true)
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD).start();
        } catch (Exception ignorado) { }
    }

    static void encerrar() {
        try { if (cef != null) cef.dispose(); } catch (Throwable ignorado) { }
        System.exit(0);
    }

    static void trocarLancador() {
        String novo = System.getProperty("fiscal.lancador.novo");
        String alvo = System.getProperty("fiscal.lancador.jar");
        if (novo == null || alvo == null) return;
        try {
            java.nio.file.Path tmp = java.nio.file.Paths.get(alvo + ".novo");
            java.nio.file.Files.copy(java.nio.file.Paths.get(novo), tmp, java.nio.file.StandardCopyOption.REPLACE_EXISTING);
            java.nio.file.Files.move(tmp, java.nio.file.Paths.get(alvo), java.nio.file.StandardCopyOption.REPLACE_EXISTING);
        } catch (Exception ignorado) { }
    }

    public static void main(String[] args) throws Exception {
        System.setProperty("java.awt.headless", "false");
        new Thread(FiscalApplication::trocarLancador).start();
        new Thread(FiscalApplication::iniciarComWindows).start();
        boolean oculto = "1".equals(System.getProperty("fiscal.oculto"));

        ConfigurableApplicationContext ctx = SpringApplication.run(FiscalApplication.class, args);
        String porta = ctx.getEnvironment().getProperty("local.server.port");
        String url = "http://127.0.0.1:" + porta + "/login.html?boot=" + System.currentTimeMillis();

        // janela com Chromium embutido
        File perfil = new File(System.getProperty("java.io.tmpdir"), "fiscal-jcef-perfil");
        perfil.mkdirs();
        CefAppBuilder builder = new CefAppBuilder();
        builder.setInstallDir(new File(System.getProperty("user.home"), ".fiscal-jcef"));
        builder.getCefSettings().windowless_rendering_enabled = false;
        builder.getCefSettings().cache_path = perfil.getAbsolutePath();
        builder.getCefSettings().persist_session_cookies = true;
        builder.addJcefArgs("--disable-gpu", "--disable-gpu-compositing", "--disable-http-cache",
                "--disk-cache-size=1", "--enable-media-stream", "--user-data-dir=" + perfil.getAbsolutePath(),
                "--disable-background-timer-throttling", "--disable-renderer-backgrounding", "--disable-backgrounding-occluded-windows");

        CefApp cefApp = builder.build();
        cef = cefApp;
        CefClient client = cefApp.createClient();
        CefBrowser browser = client.createBrowser(url, false, false);
        navegador = browser;

        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Fiscal — You Contabilidade");
            java.util.List<Image> icones = new java.util.ArrayList<>();
            for (int s : new int[]{16, 24, 32, 48, 64, 128, 256}) {
                java.net.URL u = FiscalApplication.class.getResource("/icone/fiscal-" + s + ".png");
                if (u != null) icones.add(Toolkit.getDefaultToolkit().getImage(u));
            }
            frame.setIconImages(icones);
            if (Taskbar.isTaskbarSupported() && Taskbar.getTaskbar().isSupported(Taskbar.Feature.ICON_IMAGE) && !icones.isEmpty()) {
                Taskbar.getTaskbar().setIconImage(icones.get(icones.size() - 1));
            }
            frame.getContentPane().add(browser.getUIComponent(), BorderLayout.CENTER);
            frame.setSize(1440, 900);
            frame.setLocationRelativeTo(null);
            criarBandeja(icones);
            frame.setDefaultCloseOperation(bandeja != null ? WindowConstants.DO_NOTHING_ON_CLOSE : WindowConstants.EXIT_ON_CLOSE);
            frame.addWindowListener(new java.awt.event.WindowAdapter() {
                @Override public void windowClosing(java.awt.event.WindowEvent e) { if (bandeja != null) esconder(frame); }
            });
            janela = frame;
            if (oculto && bandeja != null) {
                Point lugar = frame.getLocation();
                frame.setLocation(-30000, -30000);
                frame.setVisible(true);
                javax.swing.Timer t = new javax.swing.Timer(7000, e -> { frame.setVisible(false); frame.setLocation(lugar); });
                t.setRepeats(false);
                t.start();
            } else {
                frame.setVisible(true);
            }
        });
    }
}
