package com.stayontrack.service;

import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
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
 * Google Gemini AI integration for study planner generation.
 * Generates time-slotted study schedules (e.g. Mon 3-6pm, 8-10pm).
 */
@Service
public class GeminiService {

    private static final String GEMINI_URL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent";
    private final ObjectMapper objectMapper = new ObjectMapper();
    private final RestTemplate restTemplate = new RestTemplate();

    @Value("${google.ai.api-key:}")
    private String apiKey;

    public boolean isAvailable() {
        return apiKey != null && !apiKey.isBlank();
    }

    /**
     * Generate a time-slotted study schedule for a week.
     * Each task has: day (1=Mon..7=Sun), startTime (HH:mm 24h format), duration, title, course.
     * Considers peak focus times (PREFER), low energy times (AVOID), rest days (SKIP).
     */
    public List<String> generateTaskSuggestionsForWeek(List<Deadline> deadlines, int availableHours,
            String feedback, LocalDate weekStart, List<String> peakFocusTimes, List<String> lowEnergyTimes,
            List<String> restDays, String typicalStudyDuration) {
        if (!isAvailable()) return List.of();

        try {
            StringBuilder prompt = new StringBuilder();
            prompt.append("You are a study planner AI. Create a WEEKLY STUDY SCHEDULE with SPECIFIC TIME SLOTS. ");
            if (peakFocusTimes != null && !peakFocusTimes.isEmpty()) {
                prompt.append("RULE #1 - PEAK FOCUS: You MUST schedule ALL sessions ONLY during these windows: ").append(String.join(", ", peakFocusTimes)).append(". ");
            }
            if (lowEnergyTimes != null && !lowEnergyTimes.isEmpty()) {
                prompt.append("RULE #2 - LOW ENERGY: You MUST NEVER schedule during: ").append(String.join(", ", lowEnergyTimes)).append(". ");
            }
            if (restDays != null && !restDays.isEmpty()) {
                prompt.append("RULE #3 - REST DAYS: You MUST NOT schedule on: ").append(String.join(", ", restDays)).append(". ");
            }
            prompt.append("Each task MUST have a concrete time (e.g. Monday 3:00 PM, Tuesday 8:00 PM). ");
            prompt.append("CRITICAL - SPREAD ACROSS DAYS: This is a WEEKLY study plan. Use as many AVAILABLE days as possible. ");
            if (restDays != null && !restDays.isEmpty()) {
                prompt.append("You may NOT schedule on rest days: ").append(String.join(", ", restDays)).append(". ");
                prompt.append("So use ALL other weekdays. Example: if rest days are Sat+Sun, use Mon Tue Wed Thu Fri - spread tasks across these 5 days. ");
            }
            prompt.append("If exam is Saturday, user has Mon-Fri to revise - use multiple days (e.g. Tue, Wed, Thu, Fri). Put at most 2-3 sessions per day. ");
            prompt.append("CRITICAL: Sessions must NEVER overlap - each session needs a unique time slot. Stagger sessions (e.g. 9am, 11:30am, 2pm, 7pm) so no two sessions on the same day overlap. ");
            prompt.append("When a deadline is within 1 week, schedule 2+ sessions per day for that item to allow adequate preparation, but still respect rest and focus preferences. ");
            if (weekStart != null) {
                prompt.append("Generate ONLY for this week starting ").append(weekStart.format(DateTimeFormatter.ISO_LOCAL_DATE)).append(". ");
                prompt.append("Today is ").append(LocalDate.now().format(DateTimeFormatter.ISO_LOCAL_DATE)).append(" - do NOT schedule any task for dates before today. ");
            }
            prompt.append("Total study hours to schedule this week: ").append(availableHours).append(". ");
            if (typicalStudyDuration != null && !typicalStudyDuration.isBlank()) {
                prompt.append("RULE #4 - TYPICAL SESSION: User's typical study session is ").append(typicalStudyDuration).append(". ");
                prompt.append("Keep each session at most this length. INSERT 15-30 minute breaks between consecutive sessions - do NOT schedule back-to-back. ");
                prompt.append("Example: 9am-10am, 10:30am-11:30am, 2pm-3pm - never 9am-10am, 10am-11am. ");
            }
            if (feedback != null && !feedback.isBlank()) {
                prompt.append("User feedback: ").append(feedback).append(". ");
            }
            if (!deadlines.isEmpty()) {
                prompt.append("CRITICAL - Create study tasks for ALL of these items. You MUST include at least one task for EACH item. Do not skip any: ");
                for (Deadline d : deadlines) {
                    String due = d.getDueDate() != null ? d.getDueDate().format(DateTimeFormatter.ISO_LOCAL_DATE) : "?";
                    prompt.append(d.getCourse()).append(" ").append(d.getTitle()).append(" (").append(d.getType()).append(") due ").append(due).append("; ");
                }
                prompt.append("Exams (type=exam) MUST have preparation tasks - include at least one 'Prepare for' task per exam. ");
                prompt.append("Assignments MUST have tasks - include at least one 'Work on' task per assignment. ");
                prompt.append("Prioritize items due soonest. Never schedule tasks for deadlines that have already passed. Never schedule any task for a date before today. ");
            }
            prompt.append("Return ONLY a JSON array. Each object: day (1=Mon..7=Sun), startTime (HH:mm 24h), duration (e.g. \"2 hours\"), title, course. ");
            prompt.append("Use DIFFERENT days. Example: [{\"day\":1,\"startTime\":\"15:00\",\"duration\":\"2 hours\",\"title\":\"Review Chapter 5\",\"course\":\"CS1234\"},{\"day\":3,\"startTime\":\"17:00\",\"duration\":\"1 hour\",\"title\":\"Practice problems\",\"course\":\"CS1234\"},{\"day\":5,\"startTime\":\"10:00\",\"duration\":\"1 hour\",\"title\":\"Quiz prep\",\"course\":\"MATH101\"}]");

            String response = callGemini(prompt.toString());
            return parseTimeSlottedSuggestions(response);
        } catch (Exception e) {
            e.printStackTrace();
            return List.of();
        }
    }

    public List<String> generateTaskSuggestions(List<Deadline> deadlines, int availableHours, String feedback) {
        return generateTaskSuggestionsForWeek(deadlines, availableHours, feedback, null, null, null, null, null);
    }

    public List<String> generateTaskSuggestionsForWeek(List<Deadline> deadlines, int availableHours,
            String feedback, LocalDate weekStart) {
        return generateTaskSuggestionsForWeek(deadlines, availableHours, feedback, weekStart, null, null, null, null);
    }

    private String callGemini(String prompt) throws Exception {
        String url = GEMINI_URL + "?key=" + apiKey;
        String body = objectMapper.writeValueAsString(java.util.Map.of(
                "contents", List.of(java.util.Map.of(
                        "parts", List.of(java.util.Map.of("text", prompt))
                )),
                "generationConfig", java.util.Map.of(
                        "temperature", 0.5,
                        "maxOutputTokens", 2048
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

    private List<String> parseTimeSlottedSuggestions(String response) {
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
                int day = node.path("day").asInt(1);
                String startTime = node.path("startTime").asText("09:00");
                tasks.add(title + "|" + course + "|" + duration + "|" + day + "|" + startTime);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return tasks;
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
                int day = node.path("day").asInt(1);
                String startTime = node.has("startTime") ? node.path("startTime").asText("09:00") : "09:00";
                tasks.add(title + "|" + course + "|" + duration + "|" + day + "|" + startTime);
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return tasks;
    }
}
