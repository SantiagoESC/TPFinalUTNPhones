package edu.utn.phones.Abstract.Iterfaces;

import edu.utn.phones.Exceptions.GeneralExceptions.ResourceNotFoundException;

import java.util.List;

public interface IAbstractCrud <T> {

    public T add (T newT);

    public T update(T updatedT);

    public void delete(T ToDelete);

    public T getById(Integer id) throws ResourceNotFoundException;

    public List<T> getAll();

    public <F> List<T> getAll(F filter);


}
