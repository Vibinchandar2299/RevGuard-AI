package com.recoverai.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ActionType {
    RETRY("RETRY"),
    REQUEST_UPDATE("REQUEST_UPDATE"),
    BLOCK("BLOCK"),
    ESCALATE("ESCALATE");

    private final String value;

    ActionType(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static ActionType fromValue(String value) {
        if (value == null) {
            return ESCALATE;
        }
        for (ActionType action : values()) {
            if (action.value.equalsIgnoreCase(value.trim()) || action.name().equalsIgnoreCase(value.trim())) {
                return action;
            }
        }
        return ESCALATE;
    }
}
