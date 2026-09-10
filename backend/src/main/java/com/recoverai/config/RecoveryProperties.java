package com.recoverai.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.math.BigDecimal;

@Configuration
@ConfigurationProperties(prefix = "recovery")
@Getter
@Setter
public class RecoveryProperties {

    /**
     * Selected recovery executor: mock or razorpay (default: mock)
     */
    private String executor = "mock";

    /**
     * Autonomous recovery amount cap (Rs 20,000)
     */
    private BigDecimal autonomousAmountCap = new BigDecimal("20000.00");

    /**
     * Groq AI Diagnosis configuration
     */
    private GroqProperties groq = new GroqProperties();

    @Getter
    @Setter
    public static class GroqProperties {
        private String apiKey = "";
        private String model = "llama-3.3-70b-versatile";
        private String baseUrl = "https://api.groq.com/openai/v1";
        private int timeoutMs = 5000;
        private boolean mockFallbackEnabled = true;
    }
}
