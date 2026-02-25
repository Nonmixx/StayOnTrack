package com.stayontrack.model;

import java.util.List;

public class GroupMember {
    private String name;
    private List<String> strengths;

    // Constructors
    public GroupMember() {}

    public GroupMember(String name, List<String> strengths) {
        this.name = name;
        this.strengths = strengths;
    }

    // Getters and Setters
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public List<String> getStrengths() { return strengths; }
    public void setStrengths(List<String> strengths) { this.strengths = strengths; }
}