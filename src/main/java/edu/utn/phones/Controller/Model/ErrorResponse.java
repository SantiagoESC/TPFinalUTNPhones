package edu.utn.phones.Controller.Model;

import lombok.Builder;
import lombok.Data;
@Data @Builder
public class ErrorResponse {
    int code;
    String message ;
}