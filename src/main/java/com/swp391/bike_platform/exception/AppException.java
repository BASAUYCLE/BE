package com.swp391.bike_platform.exception;

import com.swp391.bike_platform.enums.ErrorCode;
import lombok.Getter;

@Getter
public class AppException extends RuntimeException {
    private ErrorCode errorCode;

    public AppException(ErrorCode errorCode) {
        super(errorCode.getMessage());
        this.errorCode = errorCode;
    }
}
