package;

import kiss.Prelude;

@:build(kiss.Kiss.build())
class Player extends KinematicBody {
    // Don't forget to rebuild the project so the editor knows about the new export variable.
    // TODO is it possible to provide the export annotation from .kiss?
    // How fast the player moves in meters per second.
    @:export public var speed = 14;

    // The downward acceleration when in the air, in meters per second squared.
    @:export public var fallAcceleration = 75;
}
