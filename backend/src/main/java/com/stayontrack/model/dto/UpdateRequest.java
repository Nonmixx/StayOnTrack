package com.stayontrack.model.dto;

public class UpdateRequest {

    private String uid;
    private String username;
    private String contact;
    private String password;

    public UpdateRequest() {}

    public String getUid()      { return uid; }
    public String getUsername() { return username; }
    public String getContact()  { return contact; }
    public String getPassword() { return password; }

    public void setUid(String uid)           { this.uid = uid; }
    public void setUsername(String username) { this.username = username; }
    public void setContact(String contact)   { this.contact = contact; }
    public void setPassword(String password) { this.password = password; }
}