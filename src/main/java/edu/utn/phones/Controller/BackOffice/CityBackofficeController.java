package edu.utn.phones.Controller.BackOffice;

import edu.utn.phones.Configuration.Configuration;
import edu.utn.phones.Controller.Model.CityController;
import edu.utn.phones.Exceptions.GeneralExceptions.NoContentToShowException;
import edu.utn.phones.Exceptions.GeneralExceptions.ResourceNotFoundException;
import edu.utn.phones.Domain.City;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;


@RestController
@RequestMapping("/api/backoffice/city")
public class CityBackofficeController {


    private final CityController cityController;

    //region Constructor
    @Autowired
    public CityBackofficeController(CityController cityController) {
        this.cityController = cityController;
    }
    //endregion


    //region ABM

    @PostMapping("/")
    public ResponseEntity add(@RequestBody City newCity){
        City c =  this.cityController.add(newCity);
        return  ResponseEntity.created(Configuration.getLocation(c)).build();
    }

    @PutMapping("/{idCity}")
    public ResponseEntity update(@RequestBody City updatedCity, @PathVariable Integer idCity) throws ResourceNotFoundException {
        City c = this.cityController.getById(idCity);
        updatedCity.setIdCity(c.getIdCity());
        this.cityController.update(updatedCity);
        return ResponseEntity.ok().build();
    }

    @DeleteMapping("/{idCity}")
    public ResponseEntity delete(@PathVariable Integer idCity) throws ResourceNotFoundException {
        //todo solcuinar si quiero borrar una entidad referenciada, la excepcion.
        City c =this.cityController.getById(idCity);
        this.cityController.delete(c);
        return ResponseEntity.ok().build();


    }

    //endregion


    //region GET

    @GetMapping("/{idCity}")
    public ResponseEntity<City> getById(@PathVariable Integer idCity ) throws ResourceNotFoundException {

        City c = this.cityController.getById(idCity);
        return ResponseEntity.ok().body(c);

    }

    @GetMapping("/")
    public ResponseEntity<List<City>> getAll() throws NoContentToShowException {
        List<City> cities = this.cityController.getAll();

        return ResponseEntity.ok().body(cities);
    }


    //endregion



}
