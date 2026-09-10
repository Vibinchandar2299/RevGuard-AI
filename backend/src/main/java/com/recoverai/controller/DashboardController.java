package com.recoverai.controller;

import com.recoverai.dto.AuditFeedItemResponse;
import com.recoverai.dto.DashboardSummaryResponse;
import com.recoverai.dto.ReasonBreakdownResponse;
import com.recoverai.service.DashboardService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/dashboard")
@RequiredArgsConstructor
@Slf4j
@CrossOrigin(origins = "*")
public class DashboardController {

    private final DashboardService dashboardService;

    @GetMapping("/summary")
    public ResponseEntity<DashboardSummaryResponse> getSummary() {
        return ResponseEntity.ok(dashboardService.getDashboardSummary());
    }

    @GetMapping("/reasons")
    public ResponseEntity<List<ReasonBreakdownResponse>> getReasons() {
        return ResponseEntity.ok(dashboardService.getReasonBreakdown());
    }

    @GetMapping("/audit-feed")
    public ResponseEntity<List<AuditFeedItemResponse>> getAuditFeed(@RequestParam(defaultValue = "25") int limit) {
        return ResponseEntity.ok(dashboardService.getRecentAuditFeed(limit));
    }
}
