package edu.utn.phones.Service;


import edu.utn.phones.Exceptions.CityNotExistsException;
import edu.utn.phones.Exceptions.NoContentToShowException;
import edu.utn.phones.Model.City;
import edu.utn.phones.Model.User;
import edu.utn.phones.Repository.ICityRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class CityService {

    @Autowired
    ICityRepository cityRepository;


    //region ABM

    public void add(City city){
        this.cityRepository.save(city);

    }

    //endregion

    //region SELECT

    public City getById(Integer id ) throws CityNotExistsException {
        return this.cityRepository.findById(id).orElseThrow(CityNotExistsException::new);
    }

    public List<City> getAll() throws NoContentToShowException {
        List<City> cities=this.cityRepository.findAll();

        if (cities.isEmpty()){
            throw new NoContentToShowException();
        }
        return cities;
    }

    //endregion
}
