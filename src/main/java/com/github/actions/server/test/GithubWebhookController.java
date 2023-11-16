package com.github.actions.server.test;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class GithubWebhookController {

    @PostMapping("/github-webhook")
    public ResponseEntity<String> handleGithubWebhook(@RequestBody String payload) {
        System.out.println("Received payload from GitHub: " + payload);
        return ResponseEntity.ok("Payload received");
    }
}
