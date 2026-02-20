package com.stayontrack.service;

import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stayontrack.model.Deadline;

/**
 * Google Gemini AI integration for plan generation.
 * Requires google.ai.api-key in application.properties or environment.
 */
@Service
public class GeminiService {

    // API endpoint (no key here). The API key from application.properties is passed as ?key=.
    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${google.ai.api-key:}")
    private String apiKey;

    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }

    /**
     * Ask Gemini to generate study tasks for the week based on deadlines.
     */
    public List<String> generateTaskSuggestions(List<Deadline> deadlines, int availableHours, String feedback) {
        if (!isAvailable()) return List.of();

        try {
            StringBuilder prompt = new StringBuilder();
            prompt.append("You are a study planner AI. Generate 5-7 specific study tasks for the next week. ");
            prompt.append("Available study hours: ").append(availableHours).append(". ");
            if (feedback != null && !feedback.isBlank()) {
                prompt.append("User feedback: ").append(feedback).append(". ");
            }
            if (!deadlines.isEmpty()) {
                prompt.append("Upcoming deadlines: ");
                for (Deadline d : deadlines) {
                    prompt.append(d.getCourse()).append(" ").append(d.getTitle())
                            .append(" (").append(d.getType()).append(") due soon. ");
                }
            }
            prompt.append("Return ONLY a JSON array of task objects, each with: title, course, duration (e.g. \"1 hour\"), day (1-5 for Mon-Fri). ");
            prompt.append("Example: [{\"title\":\"Review Chapter 5\",\"course\":\"CS1234\",\"duration\":\"1.5 hours\",\"day\":1}]");

            String response = callGemini(prompt.toString());
            return parseTaskSuggestions(response);
        } catch (Exception e) {
            e.printStackTrace();
            return List.of();
        }
    }

    private String callGemini(String prompt) throws Exception {
        String url = GEMINI_URL + "?key=" + apiKey;
        String body = objectMapper.writeValueAsString(java.util.Map.of(
                "contents", List.of(java.util.Map.of(
                        "parts", List.of(java.util.Map.of("text", prompt))
                )),
                "generationConfig", java.util.Map.of(
                        "temperature", 0.7,
                        "maxOutputTokens", 1024
                )
        ));

        HttpHeaders headers = new HttpHeaders();
        headers.setContentType(MediaType.APPLICATION_JSON);
        HttpEntity<String> entity = new HttpEntity<>(body, headers);
        String response = restTemplate.postForObject(url, entity, String.class);

        if (response == null) throw new RuntimeException("Empty Gemini response");

        JsonNode root = objectMapper.readTree(response);
        JsonNode candidates = root.path("candidates");
        if (candidates.isEmpty()) throw new RuntimeException("No candidates in Gemini response");
        JsonNode content = candidates.get(0).path("content").path("parts");
        if (content.isEmpty()) throw new RuntimeException("No content in Gemini response");
        return content.get(0).path("text").asText();
    }

    private List<String> parseTaskSuggestions(String response) {
        List<String> tasks = new java.util.ArrayList<>();
        try {
            String json = response;
            int start = json.indexOf('[');
            int end = json.lastIndexOf(']');
            if (start >= 0 && end > start) {
                json = json.substring(start, end + 1);
            }
            JsonNode arr = objectMapper.readTree(json);
            for (JsonNode node : arr) {
                String title = node.path("title").asText();
                String course = node.path("course").asText("General");
                String duration = node.path("duration").asText("1 hour");
                tasks.add(title + "|" + course + "|" + duration);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return tasks;
    }
}
