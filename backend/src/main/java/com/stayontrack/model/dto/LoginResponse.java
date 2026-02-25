package com.stayontrack.model.dto;

public class LoginResponse {

    private String uid;
    private String email;
    private String username;
    private String contact;   // ← NEW: loaded from Firestore on login
    private String idToken;
    private String message;

    public LoginResponse() {}

    public LoginResponse(String uid, String email, String username,
                         String contact, String idToken, String message) {
        this.uid      = uid;
        this.email    = email;
        this.username = username;
        this.contact  = contact;
        this.idToken  = idToken;
        this.message  = message;
    }

    public String getUid()      { return uid; }
    public void   setUid(String uid) { this.uid = uid; }

    public String getEmail()    { return email; }
    public void   setEmail(String email) { this.email = email; }

    public String getUsername() { return username; }
    public void   setUsername(String username) { this.username = username; }

    public String getContact()  { return contact; }
    public void   setContact(String contact) { this.contact = contact; }

    public String getIdToken()  { return idToken; }
    public void   setIdToken(String idToken) { this.idToken = idToken; }

    public String getMessage()  { return message; }
    public void   setMessage(String message) { this.message = message; }
}