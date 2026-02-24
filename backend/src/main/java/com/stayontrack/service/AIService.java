package com.stayontrack.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;

@Service
public class AIService {

    @Value("${spring.ai.google.api-key:${GOOGLE_AI_API_KEY:}}")
    private String apiKey;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    private static final String GEMINI_URL =
        "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=";

    public List<Map<String, Object>> extractTasks(String brief,
                                                   List<Map<String, Object>> members) {
        String prompt = """
            Given this assignment brief:
            "%s"
            
            Extract 4-7 concrete tasks needed to complete this assignment.
            For each task provide:
            - title (short, action-oriented)
            - description (2 sentences)
            - effort: "Low", "Medium", or "High"
            - dependencies: task number it depends on, or null
            
            Respond ONLY with a JSON array, no markdown, no explanation. Example:
            [{"title":"...","description":"...","effort":"Medium","dependencies":null}]
            """.formatted(brief);

        System.out.println("🤖 Calling Gemini for task extraction...");
        List<Map<String, Object>> result = callGeminiForJson(prompt);
        System.out.println("🤖 Gemini returned " + result.size() + " tasks");
        return result;
    }

    public List<Map<String, Object>> distributeTasks(
            List<Map<String, Object>> tasks,
            List<Map<String, Object>> members) {

        String membersJson = toJson(members);
        String tasksJson = toJson(tasks);

        String prompt = """
            Distribute these tasks fairly among the group members based on their strengths.
            
            Members: %s
            Tasks: %s
            
            For each member return:
            - name, initial (first letter of name), strengths (comma-separated string)
            - taskCount (int)
            - tasks: array of assigned tasks, each with:
              title, description, effort, reason (why this member), dependencies
            
            Respond ONLY with a JSON array, no markdown, no explanation.
            """.formatted(membersJson, tasksJson);

        System.out.println("🤖 Calling Gemini for task distribution...");
        List<Map<String, Object>> result = callGeminiForJson(prompt);
        System.out.println("🤖 Gemini returned distribution for " + result.size() + " members");
        return result;
    }

    private List<Map<String, Object>> callGeminiForJson(String prompt) {

        if (apiKey == null || apiKey.isBlank()) {
            System.err.println("❌ Gemini API key is missing! Check GOOGLE_AI_API_KEY in application.properties");
            return Collections.emptyList();
        }

        try {
            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);

            Map<String, Object> part = Map.of("text", prompt);
            Map<String, Object> content = Map.of("parts", List.of(part));
            Map<String, Object> requestBody = Map.of("contents", List.of(content));

            HttpEntity<Map<String, Object>> request = new HttpEntity<>(requestBody, headers);

            System.out.println("📡 POST " + GEMINI_URL.replace(apiKey, "***") + "***");

            ResponseEntity<Map> response = restTemplate.postForEntity(
                GEMINI_URL + apiKey,
                request,
                Map.class
            );

            System.out.println("📡 Gemini HTTP status: " + response.getStatusCode());

            if (response.getBody() == null) {
                System.err.println("❌ Gemini returned null body");
                return Collections.emptyList();
            }

            if (response.getBody().containsKey("error")) {
                System.err.println("❌ Gemini API error: " + response.getBody().get("error"));
                return Collections.emptyList();
            }

            List<Map<String, Object>> candidates =
                (List<Map<String, Object>>) response.getBody().get("candidates");

            if (candidates == null || candidates.isEmpty()) {
                System.err.println("❌ Gemini returned no candidates. Full response: " + response.getBody());
                return Collections.emptyList();
            }

            Map<String, Object> firstCandidate = candidates.get(0);
            Map<String, Object> contentMap =
                (Map<String, Object>) firstCandidate.get("content");
            List<Map<String, Object>> parts =
                (List<Map<String, Object>>) contentMap.get("parts");
            String text = (String) parts.get(0).get("text");

            System.out.println("📝 Gemini raw response: " + text);

            text = text.replaceAll("(?s)```json\\s*", "")
                       .replaceAll("(?s)```\\s*", "")
                       .trim();

            int arrayStart = text.indexOf('[');
            int arrayEnd = text.lastIndexOf(']');
            if (arrayStart == -1 || arrayEnd == -1) {
                System.err.println("❌ No JSON array found in Gemini response: " + text);
                return Collections.emptyList();
            }
            text = text.substring(arrayStart, arrayEnd + 1);

            return objectMapper.readValue(text, List.class);

        } catch (Exception e) {
    
            System.err.println("❌ Gemini call failed: " + e.getMessage());
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            return "[]";
        }
    }
}