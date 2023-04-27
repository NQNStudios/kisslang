# hollywoo
Portable interface for kinetic novel dev/animated filmmaking

## Principles

TODO explain Director

## Maintenance

### How to add a type to Director:

You must add the type parameter in many places:

* Movie.hx (on class Movie)
* Scene.hx (on typedef Scene) (if scenes will contain it)
* Movie.kiss (on properties director and scenes, and method _showScene)
* Director.hx (on class Director AND field movie)
* YourMovieType.hx, YourMovieType.kiss and YourDirectorType.hx, YourDirectorType.kiss in your Hollywoo director implementation