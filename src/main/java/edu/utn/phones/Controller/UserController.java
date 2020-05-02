package edu.utn.phones.Controller;


import edu.utn.phones.Model.User;
import edu.utn.phones.Service.UserService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.sql.SQLOutput;
import java.util.List;

@RestController
@RequestMapping("/user")
public class UserController {

    //region serviceObject
    @Autowired
    UserService userService;
    //endregion


    @PostMapping("/add")
    public void add(@RequestBody  User user){

        this.userService.add(user);

    }

    @PostMapping("/addSome")
    public void addSome(@RequestBody List<User> users){

        this.userService.addSome(users);

    }

    @GetMapping("/get/{dni}")
    public @ResponseBody User getByDni(@PathVariable Integer dni ){

        System.out.println("El dni es: "+dni);
        User u = this.userService.getByDni(dni);
        System.out.println("Volvi de service");
        System.out.println(u);
        return u;
    }


    @GetMapping("/getAll")
    public List<User> getAll(){


        return this.userService.getAll();
    }


}