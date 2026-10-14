package com.you.fiscal;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        if (!FrenteVps.ativo()) return;
        String local = FrenteVps.pasta().toUri().toString();
        registry.addResourceHandler("/**")
                .addResourceLocations(local.endsWith("/") ? local : local + "/", "classpath:/static/")
                .setCachePeriod(0);
    }
}
