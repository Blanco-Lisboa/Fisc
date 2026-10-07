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

    public static void main(String[] args) throws Exception {
        System.setProperty("java.awt.headless", "false");

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
        CefClient client = cefApp.createClient();
        CefBrowser browser = client.createBrowser(url, false, false);

        SwingUtilities.invokeLater(() -> {
            JFrame frame = new JFrame("Fiscal — You Contabilidade");
            frame.getContentPane().add(browser.getUIComponent(), BorderLayout.CENTER);
            frame.setSize(1440, 900);
            frame.setLocationRelativeTo(null);
            frame.setDefaultCloseOperation(WindowConstants.EXIT_ON_CLOSE);
            frame.setVisible(true);
        });
    }
}
