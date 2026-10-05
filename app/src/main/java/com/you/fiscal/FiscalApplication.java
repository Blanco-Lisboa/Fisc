package com.you.fiscal;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

/**
 * Ponto de entrada Spring Boot. Não sobe servidor web: quem desenha a tela é
 * o JavaFX (ver {@link JavaFxApplication}). O Spring aqui existe para dar
 * contexto/DI ao restante do app (troca futura: em vez de ler o HTML estático,
 * os dados virão de serviços Spring que já chamam as RPCs/API reais).
 */
@SpringBootApplication
public class FiscalApplication {

    public static void main(String[] args) {
        // Delega para o Application.launch do JavaFX, que por sua vez sobe
        // o contexto Spring dentro de si (ver JavaFxApplication.init()).
        JavaFxApplication.main(args);
    }
}
