package com.recoverai.model.enums;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum ReasonCode {
    INSUFFICIENT_FUNDS("insufficient_funds"),
    NETWORK_TIMEOUT("network_timeout"),
    BANK_DECLINED("bank_declined"),
    CARD_EXPIRED("card_expired"),
    FRAUD_SUSPECTED("fraud_suspected"),
    OTHER("other");

    private final String value;

    ReasonCode(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static ReasonCode fromValue(String value) {
        if (value == null) {
            return OTHER;
        }
        for (ReasonCode code : values()) {
            if (code.value.equalsIgnoreCase(value.trim()) || code.name().equalsIgnoreCase(value.trim())) {
                return code;
            }
        }
        return OTHER;
    }
}
