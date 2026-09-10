package com.recoverai.controller;

import com.recoverai.dto.MessageActionRequest;
import com.recoverai.dto.MessageDraftResponse;
import com.recoverai.service.DraftService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/messages")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class MessageController {

    private final DraftService draftService;

    @GetMapping("/drafts")
    public ResponseEntity<List<MessageDraftResponse>> getDrafts() {
        return ResponseEntity.ok(draftService.getPendingDrafts());
    }

    @GetMapping
    public ResponseEntity<List<MessageDraftResponse>> getAll() {
        return ResponseEntity.ok(draftService.getAllMessages());
    }

    @PostMapping("/{id}/approve")
    public ResponseEntity<MessageDraftResponse> approveMessage(
            @PathVariable UUID id,
            @RequestBody(required = false) MessageActionRequest request) {
        String reviewer = request != null ? request.getReviewer() : "SYSTEM_ADMIN";
        String comments = request != null ? request.getComments() : null;
        log.info("[REST API] Approving recovery message {} by {}", id, reviewer);
        return ResponseEntity.ok(draftService.approveMessage(id, reviewer, comments));
    }

    @PostMapping("/{id}/reject")
    public ResponseEntity<MessageDraftResponse> rejectMessage(
            @PathVariable UUID id,
            @RequestBody(required = false) MessageActionRequest request) {
        String reviewer = request != null ? request.getReviewer() : "SYSTEM_ADMIN";
        String comments = request != null ? request.getComments() : null;
        log.info("[REST API] Rejecting recovery message {} by {}", id, reviewer);
        return ResponseEntity.ok(draftService.rejectMessage(id, reviewer, comments));
    }
}
