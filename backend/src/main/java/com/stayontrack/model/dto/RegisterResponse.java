package com.stayontrack.model.dto;

public class RegisterResponse {

    private String uid;
    private String email;
    private String username;
    private String message;

    public RegisterResponse() {}

    public RegisterResponse(String uid, String email, String username, String message) {
        this.uid = uid;
        this.email = email;
        this.username = username;
        this.message = message;
    }

    public String getUid() { return uid; }
    public void setUid(String uid) { this.uid = uid; }

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }

    public String getUsername() { return username; }
    public void setUsername(String username) { this.username = username; }

    public String getMessage() { return message; }
    public void setMessage(String message) { this.message = message; }
}