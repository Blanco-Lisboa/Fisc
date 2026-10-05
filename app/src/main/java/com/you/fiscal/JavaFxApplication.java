package com.you.fiscal;

import javafx.application.Application;
import javafx.application.Platform;
import javafx.scene.Scene;
import javafx.scene.web.WebView;
import javafx.scene.web.WebEngine;
import javafx.stage.Stage;
import org.springframework.context.ConfigurableApplicationContext;
import org.springframework.boot.builder.SpringApplicationBuilder;

/**
 * Janela JavaFX. A tela inteira do "Fiscal · Colaborador" é o mesmo
 * HTML+CSS+JS publicado no preview (100% idêntico, nada reescrito à mão em
 * controles nativos) — carregado num {@link WebView}, que é o motor de
 * navegador embutido do JavaFX (WebKit).
 *
 * Por quê WebView e não recriar tudo em JavaFX puro?
 *  - O pedido foi "100% de tudo, nada faltando, nem uma vírgula" — qualquer
 *    reescrito manual (por melhor que fosse) divergiria em algum detalhe.
 *  - O WebView garante fidelidade 1:1 com o que foi validado no navegador.
 *  - Quando o motor de dados real (RPCs/API) estiver pronto, a ponte
 *    JS↔Java (JSObject / WebEngine.executeScript) permite trocar os dados de
 *    demonstração por dados reais sem tocar no HTML/CSS.
 */
public class JavaFxApplication extends Application {

    private ConfigurableApplicationContext springContext;

    public static void main(String[] args) {
        Application.launch(JavaFxApplication.class, args);
    }

    @Override
    public void init() {
        // Sobe o contexto Spring (sem servidor web) antes de desenhar a janela.
        springContext = new SpringApplicationBuilder(FiscalApplication.class)
                .headless(false)
                .web(org.springframework.boot.WebApplicationType.NONE)
                .run();
    }

    @Override
    public void start(Stage stage) {
        WebView webView = new WebView();
        WebEngine engine = webView.getEngine();
        engine.setJavaScriptEnabled(true);

        // Carrega o front completo (index.html) embutido nos recursos do jar.
        String indexUrl = getClass().getResource("/web/index.html").toExternalForm();
        engine.load(indexUrl);

        Scene scene = new Scene(webView, 1440, 900);
        stage.setTitle("Fiscal · Colaborador — You Contabilidade (IT.FC)");
        stage.setScene(scene);
        stage.show();
    }

    @Override
    public void stop() {
        if (springContext != null) {
            springContext.close();
        }
        Platform.exit();
    }
}
