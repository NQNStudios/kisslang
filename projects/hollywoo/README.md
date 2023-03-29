# hollywoo
Portable interface for kinetic novel dev/animated filmmaking

## Principles

TODO explain Director

## Maintenance

### How to add a type to Director:

You must add the type parameter in many places:

* Movie.hx (on class Movie)
* Movie.kiss (on prop director)
* Scene.hx (on typedef Scene) (if scenes will contain it)
* Director.hx (on class Director AND field movie)
* YourMovieType.hx, YourMovieType.kiss and YourDirectorType.hx, YourDirectorType.kiss in your Hollywoo director implementation