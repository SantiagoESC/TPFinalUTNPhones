package edu.utn.phones.Controller.Model;


import edu.utn.phones.Abstract.AbstractController;
import edu.utn.phones.Abstract.AbstractService;
import edu.utn.phones.Model.PhoneLine;
import edu.utn.phones.Service.PhoneLineService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Controller;

import java.util.List;

@Controller
public class PhoneLineController extends AbstractController<PhoneLine, PhoneLineService> {



    @Autowired
    public PhoneLineController(PhoneLineService service) {
        super(service);
    }







}