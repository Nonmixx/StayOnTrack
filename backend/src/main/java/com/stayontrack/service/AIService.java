package com.stayontrack.service;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.*;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import java.util.*;
import java.util.concurrent.atomic.AtomicInteger;

@Service
public class AIService {

    @Value("${spring.ai.google.api-key:${GOOGLE_AI_API_KEY:}}")
    private String apiKey;

    private final RestTemplate restTemplate;
    private final ObjectMapper objectMapper = new ObjectMapper();
    private String lastGeminiFailureReason = "Unknown Gemini failure";
    private final AtomicInteger fallbackDistributionCounter = new AtomicInteger(0);
    private static final int TITLE_MAX_WORDS = 8;
    private static final int DESCRIPTION_MAX_WORDS = 20;
    private static final int TITLE_MAX_CHARS = 40;
    private static final int DESCRIPTION_MAX_CHARS = 100;

    private static final String GEMINI_URL =
    "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent?key=";

    public AIService() {
        SimpleClientHttpRequestFactory requestFactory = new SimpleClientHttpRequestFactory();
        requestFactory.setConnectTimeout(10000);
        requestFactory.setReadTimeout(90000);
        this.restTemplate = new RestTemplate(requestFactory);
    }

    public List<Map<String, Object>> extractTasks(String brief,
                                                   List<Map<String, Object>> members) {
        
        // Debug: Show brief being processed
        String briefPreview = brief != null && brief.length() > 200 
            ? brief.substring(0, 200) + "..." 
            : brief;
        System.out.println("=".repeat(80));
        System.out.println("📋 TASK EXTRACTION REQUEST");
        System.out.println("=".repeat(80));
        System.out.println("Brief preview: " + briefPreview);
        System.out.println("Member count: " + (members == null ? 0 : members.size()));
        System.out.println("-".repeat(80));
        
        String prompt = """
            ACT AS A PROJECT MANAGER.

            [GOAL]
            Extract 5-8 concrete tasks from the brief.

            [STRICT STYLE GUIDE - FOLLOW EXAMPLES]
            - Bad Title: "Researching the market trends and competitor analysis for the fashion app"
            - Good Title: "Conduct Competitor Market Research"

            - Bad Desc: "You should look into what other sustainable brands are doing and write a report about their manufacturing processes and ethical standards."
            - Good Desc: "Analyze competitor brands and document ethical standards."

            [QUALITY RULES]
            1. Read the full brief and avoid generic templates.
            2. Extract exact deliverables and requirements from the brief.
            3. Titles and descriptions must be complete and grammatically correct.
            4. Keep wording concise and specific to the brief.

            [CONSTRAINTS]
            - TITLE: Max 8 words.
            - DESCRIPTION: Max 20 words.
            - effort: "Low", "Medium", or "High"
            - dependencies: task ID (1-based integer) or null

            [INPUT]
            Brief: "%s"

            Return ONLY a JSON array. NO markdown, NO explanation.
            Output shorter text. If any Title is > 8 words, the system will crash. Be brief.
            """.formatted(brief);

        try {
            System.out.println("🤖 Calling Gemini AI for task extraction...");
            List<Map<String, Object>> result = callGeminiForJson(prompt);

            if (result != null && !result.isEmpty()) {
                result = enforceStandaloneTaskTextConstraints(result);
                System.out.println("✅ Gemini successfully returned " + result.size() + " tasks");
                System.out.println("Sample task: " + result.get(0));
                System.out.println("=".repeat(80));
                return result;
            }

            System.err.println("⚠️ Gemini returned empty task list. Switching to local fallback.");
        } catch (Exception e) {
            System.err.println("⚠️ Gemini failed for extractTasks. Switching to local fallback: " + e.getMessage());
        }

        List<Map<String, Object>> fallback = enforceStandaloneTaskTextConstraints(fallbackExtractTasks(brief));
        System.out.println("✅ Fallback task extraction returned " + fallback.size() + " tasks");
        System.out.println("=".repeat(80));
        return fallback;
    }

    public List<Map<String, Object>> extractTasksAiOnly(String brief,
                                                        List<Map<String, Object>> members) {
        try {
            String prompt = """
                ACT AS A PROJECT MANAGER.

                [GOAL]
                Extract 5-8 concrete tasks from the brief.

                [STRICT STYLE GUIDE - FOLLOW EXAMPLES]
                - Bad Title: "Researching the market trends and competitor analysis for the fashion app"
                - Good Title: "Conduct Competitor Market Research"

                - Bad Desc: "You should look into what other sustainable brands are doing and write a report about their manufacturing processes and ethical standards."
                - Good Desc: "Analyze competitor brands and document ethical standards."

                [CONSTRAINTS]
                - TITLE: Max 8 words.
                - DESCRIPTION: Max 20 words.
                - Every sentence must be complete and grammatically correct.
                - effort: "Low", "Medium", or "High"
                - dependencies: task ID (1-based integer) or null

                [INPUT]
                Brief: "%s"

                Return ONLY a JSON array. NO markdown, NO explanation.
                Output shorter text. If any Title is > 8 words, the system will crash. Be brief.
                """.formatted(brief == null ? "" : brief);

            System.out.println("🤖 [AI-ONLY] Calling Gemini for task extraction...");
            List<Map<String, Object>> result = callGeminiForJson(prompt);
            if (result != null && !result.isEmpty()) {
                result = enforceStandaloneTaskTextConstraints(result);
                System.out.println("✅ [AI-ONLY] Gemini returned " + result.size() + " tasks");
                return result;
            }
            System.err.println("⚠️ [AI-ONLY] Gemini returned empty result, switching to fallback.");
        } catch (Exception e) {
            System.err.println("⚠️ [AI-ONLY] Gemini failed or timed out, switching to fallback: " + e.getMessage());
        }

        List<Map<String, Object>> fallback = enforceStandaloneTaskTextConstraints(fallbackExtractTasks(brief));
        System.out.println("✅ [AI-ONLY] Fallback returned " + fallback.size() + " tasks");
        return fallback;
    }

    public String getLastGeminiFailureReason() {
        return lastGeminiFailureReason;
    }

    public List<Map<String, Object>> distributeTasks(
            List<Map<String, Object>> tasks,
            List<Map<String, Object>> members) {

        if (members == null || members.isEmpty()) {
            System.err.println("❌ distributeTasks: members list is empty!");
            return Collections.emptyList();
        }
        
        if (tasks == null || tasks.isEmpty()) {
            System.err.println("❌ distributeTasks: tasks list is empty!");
            return Collections.emptyList();
        }

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
                        - title length: MAX 8 words
                        - description length: MAX 20 words
            
            Respond ONLY with a JSON array, no markdown, no explanation.
            
            Regeneration token: %s
            """.formatted(membersJson, tasksJson, System.currentTimeMillis());

        System.out.println("🤖 Calling Gemini for task distribution...");
        List<Map<String, Object>> result = callGeminiForJson(prompt);
        if (result.isEmpty()) {
            System.out.println("⚠️ Gemini distribution returned empty. Using local fallback distributor.");
            result = fallbackDistributeTasks(tasks, members);
        }
        System.out.println("🤖 Distribution completed for " + result.size() + " members");
        return result;
    }

    public List<Map<String, Object>> generateFullPlan(String brief,
                                                      List<Map<String, Object>> members) {
        if (members == null || members.isEmpty()) {
            System.err.println("❌ generateFullPlan: members list is empty!");
            return Collections.emptyList();
        }

        String membersJson = toJson(members);
        long seed = System.currentTimeMillis();
        String prompt = """
            You are a Project Manager AI.

            INPUT:
            1. Assignment Brief: "%s"
            2. Group Members: %s

            YOUR TASK:
            1. Analyze the brief and extract 5-8 specific tasks.
            2. Distribute these tasks fairly.

            STRICT CONSTRAINTS:
            - NO TEMPLATES: Do not use generic tasks. Use ONLY information from the brief.
            - TITLE LENGTH: Maximum 8 words.
            - DESCRIPTION LENGTH: Maximum 20 words.
            - FAIRNESS: EVERY single member MUST be assigned AT LEAST ONE task. No member should have 0 tasks.
            - VARIETY: Use random seed %d to ensure a unique plan.

            OUTPUT FORMAT:
            Return ONLY a JSON array of members. Each member object must include:
            - "name", "initial", "strengths"
            - "taskCount"
            - "tasks": an array of assigned tasks, each with:
              - "title", "description", "effort" (Low/Medium/High), "reason", "dependencies"

            Return ONLY the raw JSON array. No markdown, no preamble.
            """.formatted(brief == null ? "" : brief, membersJson, seed);

        try {
            System.out.println("🚀 [MEGA-AI] Requesting full plan (Extract + Distribute)...");
            List<Map<String, Object>> raw = callGeminiForJson(prompt);
            if (isDistributionShape(raw)) {
                List<Map<String, Object>> normalized = normalizeDistribution(raw, members);
                if (!normalized.isEmpty()) {
                    enforceTaskTextConstraints(normalized);
                    ensureEveryMemberHasTask(normalized);
                    System.out.println("✅ [MEGA-AI] Gemini returned " + normalized.size() + " member distributions");
                    return normalized;
                }
            }
            System.out.println("⚠️ [MEGA-AI] Invalid/empty response. Switching to Smart Fallback.");
        } catch (Exception e) {
            System.err.println("⚠️ [MEGA-AI] Failed: " + e.getMessage() + ". Switching to Smart Fallback.");
        }

        return smartFallback(brief, members);
    }

    public List<Map<String, Object>> generateAllInOne(String brief,
                                                      List<Map<String, Object>> members) {
        return generateFullPlan(brief, members);
    }

    private List<Map<String, Object>> smartFallback(String brief,
                                                    List<Map<String, Object>> members) {
        System.out.println("⚠️ Using Smart Fallback (Brief-driven only)");
        List<Map<String, Object>> rawTasks = extractBriefDrivenTasks(brief);

        if (rawTasks.isEmpty()) {
            Map<String, Object> task = new LinkedHashMap<>();
            task.put("title", "Analyze Brief");
            task.put("description", "Break down the core requirements from the assignment text.");
            task.put("effort", "Medium");
            task.put("dependencies", null);
            rawTasks.add(task);
        }

        List<Map<String, Object>> fallback = fallbackDistributeTasks(rawTasks, members);
        enforceTaskTextConstraints(fallback);
        ensureEveryMemberHasTask(fallback);
        return fallback;
    }

    private boolean isDistributionShape(List<Map<String, Object>> raw) {
        if (raw == null || raw.isEmpty()) return false;
        Object tasks = raw.get(0).get("tasks");
        return tasks instanceof List;
    }

    private List<Map<String, Object>> normalizeDistribution(List<Map<String, Object>> raw,
                                                            List<Map<String, Object>> sourceMembers) {
        List<Map<String, Object>> normalized = new ArrayList<>();

        for (int i = 0; i < raw.size(); i++) {
            Map<String, Object> source = raw.get(i);
            Map<String, Object> memberInput = i < sourceMembers.size() ? sourceMembers.get(i) : Collections.emptyMap();

            String fallbackName = String.valueOf(memberInput.getOrDefault("name", "Member " + (i + 1)));
            String name = nonBlank(source.get("name"), fallbackName);
            String initial = nonBlank(source.get("initial"),
                    name.isBlank() ? "?" : String.valueOf(Character.toUpperCase(name.charAt(0))));

            Object strengthsRaw = source.get("strengths");
            String strengths;
            if (strengthsRaw instanceof List<?> list) {
                strengths = list.stream().map(String::valueOf).reduce((a, b) -> a + ", " + b).orElse("General");
            } else {
                String fallbackStrengths = "General";
                Object inputStrengths = memberInput.get("strengths");
                if (inputStrengths instanceof List<?> list) {
                    fallbackStrengths = list.stream().map(String::valueOf).reduce((a, b) -> a + ", " + b).orElse("General");
                }
                strengths = nonBlank(strengthsRaw, fallbackStrengths);
            }

            List<Map<String, Object>> taskList = new ArrayList<>();
            Object tasksRaw = source.get("tasks");
            if (tasksRaw instanceof List<?> items) {
                for (Object item : items) {
                    if (!(item instanceof Map<?, ?> taskMap)) continue;
                    Map<String, Object> task = new LinkedHashMap<>();
                    task.put("title", nonBlank(taskMap.get("title"), "Task"));
                    task.put("description", nonBlank(taskMap.get("description"), ""));
                    task.put("effort", nonBlank(taskMap.get("effort"), "Medium"));
                    task.put("reason", nonBlank(taskMap.get("reason"), "Assigned based on skills and workload balance."));
                    Object dependencies = taskMap.get("dependencies");
                    task.put("dependencies", dependencies);
                    taskList.add(task);
                }
            }

            Map<String, Object> member = new LinkedHashMap<>();
            member.put("name", name);
            member.put("initial", initial);
            member.put("strengths", strengths);
            member.put("taskCount", taskList.size());
            member.put("tasks", taskList);
            normalized.add(member);
        }

        return normalized;
    }

    private String nonBlank(Object value, String fallback) {
        String candidate = value == null ? "" : String.valueOf(value).trim();
        return candidate.isEmpty() ? fallback : candidate;
    }

    private void enforceTaskTextConstraints(List<Map<String, Object>> distribution) {
        for (Map<String, Object> member : distribution) {
            Object tasksRaw = member.get("tasks");
            if (!(tasksRaw instanceof List<?> tasks)) continue;
            for (Object item : tasks) {
                if (!(item instanceof Map<?, ?> taskMap)) continue;
                String normalizedTitle = smartShorten(taskMap.get("title"), TITLE_MAX_WORDS, TITLE_MAX_CHARS);
                String normalizedDescription = smartShorten(taskMap.get("description"), DESCRIPTION_MAX_WORDS, DESCRIPTION_MAX_CHARS);

                ((Map<Object, Object>) taskMap).put("title", normalizedTitle.isBlank() ? "Task" : normalizedTitle);
                ((Map<Object, Object>) taskMap).put("description", normalizedDescription);
            }
            if (tasksRaw instanceof List<?> list) {
                member.put("taskCount", list.size());
            }
        }
    }

    private List<Map<String, Object>> enforceStandaloneTaskTextConstraints(List<Map<String, Object>> tasks) {
        if (tasks == null) return Collections.emptyList();
        for (Map<String, Object> task : tasks) {
            String title = smartShorten(task.get("title"), TITLE_MAX_WORDS, TITLE_MAX_CHARS);
            String description = smartShorten(task.get("description"), DESCRIPTION_MAX_WORDS, DESCRIPTION_MAX_CHARS);
            task.put("title", title.isBlank() ? "Task" : title);
            task.put("description", description);
        }
        return tasks;
    }

    private String smartShorten(Object value, int maxWords, int maxLen) {
        if (value == null) return "";
        String text = String.valueOf(value).trim().replaceAll("\\s+", " ");
        if (text.isEmpty()) return "";

        int firstEnd = -1;
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            if (ch == '.' || ch == '!' || ch == '?' || ch == '。' || ch == '！' || ch == '？') {
                firstEnd = i;
                break;
            }
        }

        String sentence = firstEnd >= 0 ? text.substring(0, firstEnd + 1).trim() : text;
        String wordControlled = applySoftWordLimit(sentence, maxWords);
        if (wordControlled.length() <= maxLen) return wordControlled;

        if (maxLen <= 3) {
            return wordControlled.substring(0, Math.min(maxLen, wordControlled.length()));
        }
        return wordControlled.substring(0, maxLen - 3).trim() + "...";
    }

    private String applySoftWordLimit(String sentence, int maxWords) {
        if (sentence == null) return "";
        String normalized = sentence.trim().replaceAll("\\s+", " ");
        if (normalized.isEmpty()) return "";

        String terminalPunctuation = "";
        char tail = normalized.charAt(normalized.length() - 1);
        if (tail == '.' || tail == '!' || tail == '?' || tail == '。' || tail == '！' || tail == '？') {
            terminalPunctuation = String.valueOf(tail);
            normalized = normalized.substring(0, normalized.length() - 1).trim();
        }

        if (normalized.isEmpty()) return terminalPunctuation;
        String[] words = normalized.split("\\s+");
        if (words.length <= maxWords) {
            return normalized + terminalPunctuation;
        }

        int cutIndex = nthWordStartIndex(normalized, maxWords + 1);
        if (cutIndex <= 0 || cutIndex > normalized.length()) {
            return normalized + terminalPunctuation;
        }

        String prefix = normalized.substring(0, cutIndex).trim();
        if (!looksSafeToCut(prefix)) {
            return normalized + terminalPunctuation;
        }

        return prefix + (terminalPunctuation.isEmpty() ? "." : terminalPunctuation);
    }

    private int nthWordStartIndex(String text, int wordNumber) {
        int wordCount = 0;
        boolean inWord = false;
        for (int i = 0; i < text.length(); i++) {
            char ch = text.charAt(i);
            boolean isWhitespace = Character.isWhitespace(ch);
            if (!isWhitespace && !inWord) {
                wordCount++;
                if (wordCount == wordNumber) {
                    return i;
                }
                inWord = true;
            } else if (isWhitespace) {
                inWord = false;
            }
        }
        return text.length();
    }

    private boolean looksSafeToCut(String text) {
        if (text.isBlank()) return false;
        String lower = text.toLowerCase(Locale.ROOT).trim();

        String[] badEndings = {
            "and", "or", "but", "with", "for", "to", "from", "of", "in", "on", "at", "by", "as", "via", "about", "into"
        };
        for (String token : badEndings) {
            if (lower.endsWith(" " + token) || lower.equals(token)) {
                return false;
            }
        }

        char last = lower.charAt(lower.length() - 1);
        return Character.isLetterOrDigit(last) || last == ')';
    }

    private void ensureEveryMemberHasTask(List<Map<String, Object>> distribution) {
        if (distribution == null || distribution.isEmpty()) return;

        for (Map<String, Object> member : distribution) {
            Object tasksRaw = member.get("tasks");
            if (!(tasksRaw instanceof List<?>)) {
                member.put("tasks", new ArrayList<Map<String, Object>>());
                member.put("taskCount", 0);
            }
        }

        for (int i = 0; i < distribution.size(); i++) {
            Map<String, Object> member = distribution.get(i);
            List<Map<String, Object>> tasks = (List<Map<String, Object>>) member.get("tasks");
            if (tasks != null && !tasks.isEmpty()) continue;

            int donorIndex = -1;
            int donorMax = 0;
            for (int j = 0; j < distribution.size(); j++) {
                if (j == i) continue;
                List<Map<String, Object>> donorTasks = (List<Map<String, Object>>) distribution.get(j).get("tasks");
                int size = donorTasks == null ? 0 : donorTasks.size();
                if (size > donorMax) {
                    donorMax = size;
                    donorIndex = j;
                }
            }

            if (donorIndex >= 0 && donorMax > 1) {
                List<Map<String, Object>> donorTasks = (List<Map<String, Object>>) distribution.get(donorIndex).get("tasks");
                Map<String, Object> moved = donorTasks.remove(donorTasks.size() - 1);
                moved.put("reason", "Rebalanced for fairness so each member has at least one task.");
                tasks.add(moved);
            } else {
                Map<String, Object> placeholder = new LinkedHashMap<>();
                placeholder.put("title", "Support Team Task");
                placeholder.put("description", "Support delivery and quality checks for the assignment output.");
                placeholder.put("effort", "Low");
                placeholder.put("reason", "Added to ensure fair baseline participation.");
                placeholder.put("dependencies", null);
                tasks.add(placeholder);
            }
        }

        for (Map<String, Object> member : distribution) {
            List<Map<String, Object>> tasks = (List<Map<String, Object>>) member.get("tasks");
            member.put("taskCount", tasks == null ? 0 : tasks.size());
        }
    }

    private List<Map<String, Object>> fallbackExtractTasks(String brief) {
        List<Map<String, Object>> tasks = new ArrayList<>();

        String normalizedBrief = brief == null ? "" : brief.toLowerCase(Locale.ROOT);

        List<Map<String, Object>> briefDrivenTasks = extractBriefDrivenTasks(brief);
        if (briefDrivenTasks.size() >= 4) {
            System.out.println("✅ Fallback generated " + briefDrivenTasks.size() + " tasks from brief deliverables");
            return briefDrivenTasks;
        }
        
        // Domain detection
        boolean hasCoding = containsAny(normalizedBrief,
            "code", "coding", "implement", "development", "develop", "program", "api", "backend", "frontend",
            "app", "system", "software", "prototype", "flutter", "java", "web", "mobile");
        
        boolean hasResearch = containsAny(normalizedBrief,
            "research", "literature", "survey", "study", "analyze", "analysis", "investigate", "methodology");
        
        boolean hasReport = containsAny(normalizedBrief,
            "report", "essay", "paper", "write", "documentation", "document", "proposal", "reflection");
        
        boolean hasPresentation = containsAny(normalizedBrief,
            "presentation", "slides", "pitch", "demo", "oral", "defense", "showcase");
        
        boolean hasDesign = containsAny(normalizedBrief,
            "design", "ui", "ux", "wireframe", "mockup", "prototype", "visual", "figma", "interface");
        
        boolean hasData = containsAny(normalizedBrief,
            "data", "dataset", "clean", "preprocess", "etl", "visualization", "dashboard", "model", "training");
        
        // NEW: Healthcare domain detection
        boolean hasHealthcare = containsAny(normalizedBrief,
            "patient", "hospital", "ward", "medical", "health", "safety", "clinical", "care", "diagnosis",
            "treatment", "nursing", "intervention", "healthcare", "health system", "quality improvement",
            "risk management", "evidence-based", "evidence based");
        
        // NEW: Business domain detection
        boolean hasBusiness = containsAny(normalizedBrief,
            "business", "marketing", "sales", "strategy", "plan", "analysis", "market", "competitive",
            "customer", "financial", "budget", "investment", "roi", "business model", "case study");

        List<Map<String, String>> templates = new ArrayList<>();

        for (Map<String, Object> extracted : briefDrivenTasks) {
            String title = String.valueOf(extracted.getOrDefault("title", ""));
            String description = String.valueOf(extracted.getOrDefault("description", ""));
            String effort = String.valueOf(extracted.getOrDefault("effort", "Medium"));
            if (!title.isBlank()) {
                templates.add(taskTemplate(title, description, effort));
            }
        }

        // Always start with scoping
        templates.add(taskTemplate(
            "Clarify requirements and scope",
            "Extract deliverables, constraints, grading criteria, and deadline from the brief. Split the assignment into concrete milestones with ownership boundaries.",
            "Medium"
        ));

        // NEW: Healthcare-specific tasks
        if (hasHealthcare) {
            System.out.println("📋 Detected Healthcare domain - using healthcare-specific tasks");
            templates.add(taskTemplate(
                "Identify top patient safety risks from literature",
                "Research published studies and case reports to identify 3 major safety risks in the selected ward type. Document evidence, prevalence, and impact on patient outcomes.",
                "High"
            ));
            templates.add(taskTemplate(
                "Propose evidence-based interventions for each risk",
                "For each identified risk, develop specific, evidence-based intervention strategies based on clinical best practices and literature. Include implementation considerations.",
                "High"
            ));
            templates.add(taskTemplate(
                "Design staff training program",
                "Create a structured training component covering the interventions, their rationale, and practical application. Include assessment methods to verify competency.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Develop monitoring framework and KPIs",
                "Establish key performance indicators (KPIs) and metrics to measure intervention effectiveness. Define data collection methods and evaluation timeline.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Create implementation timeline and milestones",
                "Develop a phased implementation plan with timelines, resource allocation, and responsibility assignments for each intervention.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Prepare written report and visual summary",
                "Compile comprehensive report with all elements and create an infographic summarizing the plan for ward staff distribution.",
                "High"
            ));
        }
        // Business-specific tasks
        else if (hasBusiness && !hasHealthcare) {
            System.out.println("📋 Detected Business domain - using business-specific tasks");
            templates.add(taskTemplate(
                "Market and competitive analysis",
                "Conduct research on target market, competitor landscape, and industry trends. Document key findings and strategic implications.",
                "High"
            ));
            templates.add(taskTemplate(
                "Develop business strategy and objectives",
                "Define clear business strategy, goals, and success metrics based on market analysis. Align strategy with resources and team capabilities.",
                "High"
            ));
            templates.add(taskTemplate(
                "Create financial projections and budget",
                "Develop realistic financial forecasts, budget allocation, and ROI analysis. Document assumptions and risk factors.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Prepare marketing and implementation plan",
                "Create detailed go-to-market strategy including marketing channels, customer acquisition, and implementation timeline.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Compile business report and presentation materials",
                "Write comprehensive business plan report and prepare executive summary with visual aids for stakeholder presentation.",
                "Medium"
            ));
        }
        // Coding-specific tasks
        else if (hasCoding) {
            templates.add(taskTemplate(
                "Design technical architecture",
                "Define modules, data flow, API contracts, and folder structure before coding. Align architecture decisions with assignment requirements and team strengths.",
                "High"
            ));
            templates.add(taskTemplate(
                "Implement core features",
                "Build the main user flows and required business logic incrementally. Keep commits scoped and ensure each feature is testable.",
                "High"
            ));
            templates.add(taskTemplate(
                "Run integration testing and bug fixes",
                "Validate end-to-end behavior across modules and external services. Resolve functional bugs and stability issues before final handoff.",
                "Medium"
            ));
        }

        // Supplementary tasks based on deliverable types
        if (hasDesign && !hasHealthcare) {
            templates.add(taskTemplate(
                "Create wireframes and UI specs",
                "Produce screen flow, component hierarchy, and interaction notes for key pages. Ensure visual choices support usability and accessibility.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Conduct design usability review",
                "Run a quick usability check with representative tasks and gather feedback. Iterate on confusing layouts or interaction points.",
                "Low"
            ));
        }

        if (hasData && !hasHealthcare) {
            templates.add(taskTemplate(
                "Prepare and validate dataset",
                "Collect or consolidate source data and clean inconsistent entries. Verify schema, missing values, and data quality before analysis.",
                "High"
            ));
            templates.add(taskTemplate(
                "Perform analysis and visualize findings",
                "Apply the required analysis methods and generate interpretable outputs. Build charts or tables that directly answer the assignment questions.",
                "High"
            ));
        }

        if (hasResearch && !hasHealthcare) {
            templates.add(taskTemplate(
                "Collect references and evidence",
                "Find credible sources and extract key arguments, metrics, and examples. Track citations while reading to avoid last-minute rework.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Synthesize insights into argument structure",
                "Group evidence into themes and define a clear thesis or problem framing. Link each section back to the assignment objective.",
                "Medium"
            ));
        }

        if (hasReport && !hasHealthcare) {
            templates.add(taskTemplate(
                "Draft report with section structure",
                "Write the first complete draft using required headings and logical transitions. Prioritize clarity, traceable claims, and concise explanation.",
                "High"
            ));
            templates.add(taskTemplate(
                "Edit and finalize documentation",
                "Proofread language, verify references, and align formatting with rubric. Ensure the final submission package is complete and consistent.",
                "Medium"
            ));
        }

        if (hasPresentation && !hasHealthcare) {
            templates.add(taskTemplate(
                "Build presentation storyline and slides",
                "Convert key results into a clear narrative with concise slide content. Highlight problem, approach, outcomes, and implications.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Rehearse demo and Q&A",
                "Practice timing, speaking transitions, and live demo flow under realistic conditions. Prepare backup screenshots and concise answers for likely questions.",
                "Low"
            ));
        }

        // Fallback if no domain detected
        if (templates.size() == 1) {
            System.out.println("⚠️ No specific domain detected - using generic fallback tasks");
            templates.add(taskTemplate(
                "Plan execution timeline",
                "Break the assignment into weekly or daily checkpoints with dependencies. Reserve contingency time for revision and submission checks.",
                "Medium"
            ));
            templates.add(taskTemplate(
                "Produce main deliverable",
                "Complete the core output required by the brief and validate it against rubric criteria. Capture assumptions and decisions for traceability.",
                "High"
            ));
            templates.add(taskTemplate(
                "Quality review before submission",
                "Perform final review for correctness, completeness, and consistency. Confirm all files and assets are ready for hand-in.",
                "Low"
            ));
        }

        // Deduplicate and build final task list
        List<Map<String, String>> uniqueTemplates = new ArrayList<>();
        Set<String> seenTitles = new HashSet<>();
        for (Map<String, String> candidate : templates) {
            String titleKey = candidate.getOrDefault("title", "").toLowerCase(Locale.ROOT);
            if (seenTitles.add(titleKey)) {
                uniqueTemplates.add(candidate);
            }
        }

        int taskCount = Math.max(4, Math.min(7, uniqueTemplates.size()));
        for (int i = 0; i < taskCount; i++) {
            Map<String, String> source = uniqueTemplates.get(i);

            String title = source.getOrDefault("title", "Task " + (i + 1));

            String description = source.getOrDefault("description", "");
            if (description.length() > 220) {
                description = description.substring(0, 217) + "...";
            }

            Map<String, Object> task = new LinkedHashMap<>();
            task.put("title", title);
            task.put("description", description);
            task.put("effort", source.getOrDefault("effort", "Medium"));

            if (i == 0) {
                task.put("dependencies", null);
            } else if (i <= 2) {
                task.put("dependencies", String.valueOf(i));
            } else {
                task.put("dependencies", String.valueOf(i - 1));
            }

            tasks.add(task);
        }

        System.out.println("✅ Fallback generated " + tasks.size() + " domain-specific tasks");
        return tasks;
    }

    private List<Map<String, Object>> extractBriefDrivenTasks(String brief) {
        List<Map<String, Object>> extracted = new ArrayList<>();
        if (brief == null || brief.isBlank()) {
            return extracted;
        }

        String cleaned = brief.replace("\r", "\n");
        String[] chunks = cleaned.split("\\n|[;；。.!?]");

        List<String> actionVerbs = List.of(
            "build", "develop", "design", "implement", "create", "analyze", "analyse",
            "research", "evaluate", "prepare", "write", "present", "propose", "test",
            "optimize", "plan", "investigate", "compare", "model", "prototype"
        );

        for (String raw : chunks) {
            String unit = raw.trim();
            if (unit.length() < 18) continue;
            String lower = unit.toLowerCase(Locale.ROOT);

            boolean hasAction = false;
            for (String verb : actionVerbs) {
                if (lower.contains(verb)) {
                    hasAction = true;
                    break;
                }
            }
            if (!hasAction) continue;

            Map<String, Object> task = new LinkedHashMap<>();
            task.put("title", toTaskTitle(unit));
            task.put("description", "Deliverable from brief: " + unit);
            task.put("effort", estimateEffortFromText(lower));
            task.put("dependencies", null);
            extracted.add(task);

            if (extracted.size() >= 8) break;
        }

        for (int i = 0; i < extracted.size(); i++) {
            if (i == 0) {
                extracted.get(i).put("dependencies", null);
            } else if (i <= 2) {
                extracted.get(i).put("dependencies", String.valueOf(i));
            } else {
                extracted.get(i).put("dependencies", String.valueOf(i - 1));
            }
        }

        return extracted;
    }

    private String toTaskTitle(String unit) {
        String title = unit.trim();
        if (title.length() <= 90) return title;
        return title.substring(0, 90).trim();
    }

    private String estimateEffortFromText(String lowerText) {
        if (containsAny(lowerText,
            "integrat", "architecture", "model", "prototype", "end-to-end", "optimization",
            "comprehensive", "framework", "multi", "complex")) {
            return "High";
        }
        if (containsAny(lowerText,
            "report", "write", "draft", "presentation", "slides", "review", "summary")) {
            return "Low";
        }
        return "Medium";
    }

    private boolean containsAny(String source, String... keywords) {
        for (String keyword : keywords) {
            if (source.contains(keyword)) {
                return true;
            }
        }
        return false;
    }

    private Map<String, String> taskTemplate(String title, String description, String effort) {
        Map<String, String> template = new LinkedHashMap<>();
        template.put("title", title);
        template.put("description", description);
        template.put("effort", effort);
        return template;
    }

    private List<Map<String, Object>> fallbackDistributeTasks(
            List<Map<String, Object>> tasks,
            List<Map<String, Object>> members) {

        if (members == null || members.isEmpty()) {
            return Collections.emptyList();
        }

        List<Map<String, Object>> distribution = new ArrayList<>();
        List<List<Map<String, Object>>> buckets = new ArrayList<>();
        int memberCount = members.size();
        int regenToken = fallbackDistributionCounter.incrementAndGet();
        int tieBreakOffset = Math.floorMod(regenToken, memberCount);
        System.out.println("🧠 Fallback balancing mode enabled (token=" + regenToken + ")");

        List<List<String>> memberStrengthLists = new ArrayList<>();
        int[] workloads = new int[memberCount];

        for (int i = 0; i < members.size(); i++) {
            Map<String, Object> member = members.get(i);
            String name = String.valueOf(member.getOrDefault("name", "Member " + (i + 1)));

            String initial = name.isBlank() ? "?" : String.valueOf(Character.toUpperCase(name.charAt(0)));
            List<?> strengthsRaw = (List<?>) member.getOrDefault("strengths", Collections.emptyList());
            List<String> strengths = strengthsRaw.stream().map(String::valueOf).toList();
            String strengthsText = strengths.isEmpty() ? "General" : String.join(", ", strengths);
            memberStrengthLists.add(strengths.stream().map(String::toLowerCase).toList());

            Map<String, Object> memberBlock = new LinkedHashMap<>();
            memberBlock.put("name", name);
            memberBlock.put("initial", initial);
            memberBlock.put("strengths", strengthsText);
            memberBlock.put("taskCount", 0);
            memberBlock.put("tasks", new ArrayList<Map<String, Object>>());

            distribution.add(memberBlock);
            buckets.add((List<Map<String, Object>>) memberBlock.get("tasks"));
        }

        List<Map<String, Object>> tasksToAssign = new ArrayList<>(tasks);
        tasksToAssign.sort((a, b) -> {
            int byEffort = Integer.compare(effortPoints(String.valueOf(b.getOrDefault("effort", "Medium"))),
                                           effortPoints(String.valueOf(a.getOrDefault("effort", "Medium"))));
            if (byEffort != 0) return byEffort;
            return Integer.compare(taskIdValue(a), taskIdValue(b));
        });

        for (int i = 0; i < tasksToAssign.size(); i++) {
            Map<String, Object> task = tasksToAssign.get(i);
            int effort = effortPoints(String.valueOf(task.getOrDefault("effort", "Medium")));
            String taskText = (String.valueOf(task.getOrDefault("title", "")) + " " +
                               String.valueOf(task.getOrDefault("description", ""))).toLowerCase(Locale.ROOT);

            int minWorkload = Arrays.stream(workloads).min().orElse(0);
            int bestScore = Integer.MIN_VALUE;
            List<Integer> candidates = new ArrayList<>();

            for (int memberIndex = 0; memberIndex < memberCount; memberIndex++) {
                List<String> strengths = memberStrengthLists.get(memberIndex);
                int matchScore = strengthMatchScore(taskText, strengths);
                int workloadScore = (minWorkload - workloads[memberIndex]) * 3;
                int total = matchScore * 10 + workloadScore;

                if (total > bestScore) {
                    bestScore = total;
                    candidates.clear();
                    candidates.add(memberIndex);
                } else if (total == bestScore) {
                    candidates.add(memberIndex);
                }
            }

            int memberIndex;
            if (candidates.size() == 1) {
                memberIndex = candidates.get(0);
            } else {
                int preferred = (i + tieBreakOffset) % memberCount;
                memberIndex = candidates.get(0);
                int bestDistance = Integer.MAX_VALUE;
                for (int candidate : candidates) {
                    int distance = Math.floorMod(candidate - preferred, memberCount);
                    if (distance < bestDistance) {
                        bestDistance = distance;
                        memberIndex = candidate;
                    }
                }
            }

            List<String> matchedStrengths = memberStrengthLists.get(memberIndex);
            String reasonBase = matchedStrengths.isEmpty()
                ? "general skills"
                : matchedStrengths.get(0);

            Map<String, Object> assignedTask = new LinkedHashMap<>();
            assignedTask.put("title", String.valueOf(task.getOrDefault("title", "Task")));
            assignedTask.put("description", String.valueOf(task.getOrDefault("description", "")));
            assignedTask.put("effort", String.valueOf(task.getOrDefault("effort", "Medium")));
            assignedTask.put("dependencies", task.get("dependencies"));
            assignedTask.put("reason", "Assigned based on " + reasonBase + " match and workload balance.");

            buckets.get(memberIndex).add(assignedTask);
            workloads[memberIndex] += effort;
        }

        for (Map<String, Object> memberBlock : distribution) {
            List<Map<String, Object>> assigned = (List<Map<String, Object>>) memberBlock.get("tasks");
            assigned.sort(Comparator.comparingInt(this::taskIdValue));
            memberBlock.put("taskCount", assigned.size());
        }

        return distribution;
    }

    private int effortPoints(String effort) {
        if (effort == null) return 2;
        return switch (effort.trim().toLowerCase(Locale.ROOT)) {
            case "high" -> 3;
            case "low" -> 1;
            default -> 2;
        };
    }

    private int taskIdValue(Map<String, Object> task) {
        Object raw = task.get("id");
        if (raw instanceof Number n) return n.intValue();
        if (raw instanceof String s) {
            try {
                return Integer.parseInt(s);
            } catch (NumberFormatException ignored) {
                return Integer.MAX_VALUE;
            }
        }
        return Integer.MAX_VALUE;
    }

    private int strengthMatchScore(String taskText, List<String> strengths) {
        if (strengths == null || strengths.isEmpty()) return 0;
        int score = 0;
        for (String strength : strengths) {
            String s = strength.toLowerCase(Locale.ROOT);
            if (taskText.contains(s)) {
                score += 2;
            }
            switch (s) {
                case "coding" -> {
                    if (containsAny(taskText, "code", "api", "backend", "frontend", "system", "develop", "implement")) score += 2;
                }
                case "research" -> {
                    if (containsAny(taskText, "research", "literature", "study", "analysis", "investigate")) score += 2;
                }
                case "writing" -> {
                    if (containsAny(taskText, "report", "write", "documentation", "summary", "paper")) score += 2;
                }
                case "design" -> {
                    if (containsAny(taskText, "design", "ui", "ux", "wireframe", "prototype", "visual")) score += 2;
                }
                case "presentation" -> {
                    if (containsAny(taskText, "presentation", "slides", "pitch", "demo", "showcase")) score += 2;
                }
                case "testing" -> {
                    if (containsAny(taskText, "test", "qa", "validate", "verify", "review")) score += 2;
                }
                default -> {
                }
            }
        }
        return score;
    }

    private List<Map<String, Object>> callGeminiForJson(String prompt) {

        if (apiKey == null || apiKey.isBlank()) {
            lastGeminiFailureReason = "API key missing (GOOGLE_AI_API_KEY not configured)";
            System.err.println("❌ Gemini API key is missing! Check GOOGLE_AI_API_KEY in application.properties");
            return Collections.emptyList();
        }

        try {
            System.out.println("📤 Sending prompt to Gemini (length: " + prompt.length() + " chars)");
            System.out.println("Prompt preview: " + prompt.substring(0, Math.min(300, prompt.length())) + "...");
            
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
                lastGeminiFailureReason = "Gemini returned empty body";
                System.err.println("❌ Gemini returned null body");
                return Collections.emptyList();
            }

            if (response.getBody().containsKey("error")) {
                Map<String, Object> error = (Map<String, Object>) response.getBody().get("error");
                lastGeminiFailureReason = String.valueOf(error.getOrDefault("message", "Gemini API error"));
                System.err.println("❌ Gemini API error: " + error);
                System.err.println("   Error details: " + error.get("message"));
                return Collections.emptyList();
            }

            return parseGeminiResponse(response.getBody());

        } catch (Exception e) {
            lastGeminiFailureReason = e.getClass().getSimpleName() + ": " + e.getMessage();
            System.err.println("❌ Gemini call failed: " + e.getClass().getName() + " - " + e.getMessage());
            e.printStackTrace();
            return Collections.emptyList();
        }
    }

    private List<Map<String, Object>> parseGeminiResponse(Map<String, Object> body) throws Exception {
        List<Map<String, Object>> candidates = (List<Map<String, Object>>) body.get("candidates");

        if (candidates == null || candidates.isEmpty()) {
            lastGeminiFailureReason = "Gemini returned no candidates";
            System.err.println("❌ Gemini returned no candidates. Full response: " + body);
            return Collections.emptyList();
        }

        Map<String, Object> firstCandidate = candidates.get(0);
        Map<String, Object> contentMap = (Map<String, Object>) firstCandidate.get("content");
        List<Map<String, Object>> parts = (List<Map<String, Object>>) contentMap.get("parts");
        String text = (String) parts.get(0).get("text");

        System.out.println("📝 Gemini raw response length: " + text.length() + " chars");
        System.out.println("📝 Response preview: " + text.substring(0, Math.min(500, text.length())));

        text = text.replaceAll("(?s)```json\\s*", "")
                   .replaceAll("(?s)```\\s*", "")
                   .trim();

        int arrayStart = text.indexOf('[');
        int arrayEnd = text.lastIndexOf(']');
        if (arrayStart == -1 || arrayEnd == -1) {
            lastGeminiFailureReason = "Gemini response is not valid JSON array";
            System.err.println("❌ No JSON array found in Gemini response");
            System.err.println("   Full cleaned text: " + text);
            return Collections.emptyList();
        }
        text = text.substring(arrayStart, arrayEnd + 1);

        List<Map<String, Object>> parsed = objectMapper.readValue(text, List.class);
        System.out.println("✅ Successfully parsed " + parsed.size() + " items from Gemini response");
        return parsed;
    }

    private String toJson(Object obj) {
        try {
            return objectMapper.writeValueAsString(obj);
        } catch (Exception e) {
            return "[]";
        }
    }
}