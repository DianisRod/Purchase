package com.example.my_project;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.GetMapping;

@Controller
public class HomeController {

    @GetMapping("/")
    public String index() {
        return "index";
    }

    @GetMapping("/login")
    public String login() {
        // Hier können Sie Ihre Login-Logik einfügen oder zu einer Login-Seite weiterleiten
        return "login"; // Diese Seite muss ebenfalls im templates-Ordner vorhanden sein
    }

    @GetMapping("/signin")
    public String signIn() {
        // Hier können Sie Ihre Sign-In-Logik einfügen oder zu einer Sign-In-Seite weiterleiten
        return "signin"; // Diese Seite muss ebenfalls im templates-Ordner vorhanden sein
    }
}
