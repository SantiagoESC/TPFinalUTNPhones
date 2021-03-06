package edu.utn.phones.Controller.Advice;

import edu.utn.phones.Exceptions.GeneralExceptions.LoginException;
import edu.utn.phones.Exceptions.GeneralExceptions.NoContentToShowException;
import edu.utn.phones.Exceptions.GeneralExceptions.ResourceNotFoundException;
import org.springframework.dao.DataIntegrityViolationException;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.orm.jpa.JpaSystemException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.ResponseStatus;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RestControllerAdvice;
import org.springframework.web.servlet.mvc.method.annotation.ResponseEntityExceptionHandler;

import java.text.ParseException;

@RestControllerAdvice
public class AdviceController extends ResponseEntityExceptionHandler {

    @ResponseStatus(HttpStatus.NO_CONTENT)
    @ExceptionHandler(NoContentToShowException.class)
    public ResponseEntity handleNoContentToShowException (Exception ex){
        return ResponseEntity.ok().body("No content to show");
    }

    @ResponseStatus(HttpStatus.NOT_FOUND)
    @ExceptionHandler(ResourceNotFoundException.class)
    public ResponseEntity handleResourceNotFoundException(){

        return ResponseEntity.notFound().build();
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(DataIntegrityViolationException.class)
    public ResponseEntity handleDataIntegrityViolationException (DataIntegrityViolationException ex){
        return ResponseEntity.badRequest().body(ex.getCause().getCause().getMessage());
    }

    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(JpaSystemException.class)
    public ResponseEntity handleJpaSystemException(JpaSystemException ex){
        return ResponseEntity.badRequest().body(ex.getCause().getCause().getMessage());
    }

    @ResponseStatus(HttpStatus.UNAUTHORIZED)
    @ExceptionHandler(LoginException.class)
    public ResponseEntity handleLoginException(){
        return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
    }



    @ResponseStatus(HttpStatus.BAD_REQUEST)
    @ExceptionHandler(ParseException.class)
    public  ResponseEntity handleParseException(){
        return ResponseEntity.badRequest().body("Bad format of dates");
    }
}
