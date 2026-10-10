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
                "--disk-cache-size=1", "--enable-media-stream", "--user-data-dir=" + perfil.getAbsolutePath());

        CefApp cefApp = builder.build();
        cef = cefApp;
        CefClient client = cefApp.createClient();
        CefBrowser browser = client.createBrowser(url, false, false);

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
            frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
            frame.setVisible(true);
            janela = frame;
        });
    }
}
